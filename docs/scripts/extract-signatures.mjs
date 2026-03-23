/**
 * Extracts component Signature interfaces from declaration files
 * and injects Signature code blocks + Args/Yields tables into component docs.
 *
 * Usage: node docs/scripts/extract-signatures.mjs
 *
 * Markers in /docs/components/*.md:
 *   <!-- DESCRIPTION --> ... <!-- /DESCRIPTION -->  → class-level JSDoc description
 *   <!-- EXAMPLE -->     ... <!-- /EXAMPLE -->      → @example code block
 *   <!-- IMPORT -->      ... <!-- /IMPORT -->       → @access tag → import/yield info
 *   <!-- SIGNATURE -->   ... <!-- /SIGNATURE -->    → raw Signature code block
 *   <!-- ARGS -->        ... <!-- /ARGS -->         → Args table + inline type definitions
 *   <!-- YIELDS -->      ... <!-- /YIELDS -->       → Yields table
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const DECL_DIR = join(import.meta.dirname, '../../declarations/components');
const DOCS_DIR = join(import.meta.dirname, '../components');

const COMPONENT_MAP = {
  'map.md': 'maplibre-gl.d.ts',
  'source.md': 'maplibre-gl-source.d.ts',
  'layer.md': 'maplibre-gl-layer.d.ts',
  'marker.md': 'maplibre-gl-marker.d.ts',
  'popup.md': 'maplibre-gl-popup.d.ts',
  'control.md': 'maplibre-gl-control.d.ts',
  'image.md': 'maplibre-gl-image.d.ts',
  'on.md': 'maplibre-gl-on.d.ts',
  'call.md': 'maplibre-gl-call.d.ts',
};

// Args that are pre-bound by the parent and not user-facing
const PREBOUND_ARGS = new Set(['map', 'parent', 'eventSource', 'obj']);

// Component class name → relative doc page (for linking yielded components)
const COMPONENT_DOC_URLS = {
  MapLibreGLCall: './call',
  MapLibreGLControl: './control',
  MapLibreGLImage: './image',
  MapLibreGLLayer: './layer',
  MapLibreGLMarker: './marker',
  MapLibreGLOn: './on',
  MapLibreGLPopup: './popup',
  MapLibreGLSource: './source',
};

// Addon exported types — linked to same-page anchors (populated per-file by parseExportedTypes)
let ADDON_TYPE_ANCHORS = {};

// MapLibre type → documentation URL mapping
const MAPLIBRE_TYPE_URLS = {
  MapOptions: 'https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/',
  Map: 'https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/',
  LngLatLike: 'https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/LngLatLike/',
  MarkerOptions: 'https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MarkerOptions/',
  PopupOptions: 'https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/PopupOptions/',
  LayerSpecification: 'https://maplibre.org/maplibre-style-spec/layers/',
  SourceSpecification: 'https://maplibre.org/maplibre-style-spec/sources/',
  FilterSpecification: 'https://maplibre.org/maplibre-style-spec/expressions/',
  IControl: 'https://maplibre.org/maplibre-gl-js/docs/API/interfaces/IControl/',
  StyleImageInterface: 'https://maplibre.org/maplibre-gl-js/docs/API/interfaces/StyleImageInterface/',
};

/**
 * Wrap known MapLibre type names in the type string with markdown links.
 * E.g. "Omit<MapOptions, 'container'>" → "Omit<[MapOptions](url), 'container'>"
 */
function linkMapLibreTypes(typeStr) {
  let result = typeStr;
  for (const [typeName, url] of Object.entries({
    ...ADDON_TYPE_ANCHORS,
    ...MAPLIBRE_TYPE_URLS,
  })) {
    // Match the type name as a whole word (not already inside a markdown link)
    const regex = new RegExp(`(?<!\\[)\\b${typeName}\\b(?!\\])`, 'g');
    result = result.replace(regex, `[${typeName}](${url})`);
  }
  return result;
}

/**
 * Extract the class-level JSDoc comment (description + @example) from the
 * declaration file. Returns { description, example } or null.
 */
function extractClassJSDoc(declContent, componentName) {
  // Match the last /** ... */ block immediately before `export default class ComponentName`.
  // Use a greedy prefix to skip earlier JSDoc blocks in the file.
  const regex = new RegExp(
    `[\\s\\S]*/\\*\\*\\s*\\n([\\s\\S]*?)\\*/\\s*\\nexport default class ${componentName}`,
  );
  const match = declContent.match(regex);
  if (!match) return null;

  const raw = match[1];

  // Split into sections by @tags
  const accessIdx = raw.indexOf('@access');
  const exampleIdx = raw.indexOf('@example');

  // Description: everything before the first @tag
  const firstTagIdx = [accessIdx, exampleIdx].filter((i) => i !== -1).sort((a, b) => a - b)[0] ?? raw.length;
  const descRaw = raw.slice(0, firstTagIdx);

  // Clean description: strip leading ` * ` prefixes and trim
  const description = descRaw
    .replace(/^\s*\* ?/gm, '')
    .replace(/\{@link (\w+)\}/g, '$1')
    .trim();

  // Extract @access tag value
  let access = null;
  if (accessIdx !== -1) {
    const accessEnd = exampleIdx !== -1 && exampleIdx > accessIdx ? exampleIdx : raw.length;
    access = raw.slice(accessIdx + '@access'.length, accessEnd)
      .replace(/^\s*\* ?/gm, '')
      .trim();
  }

  // Extract @example code block
  const exampleRaw = exampleIdx !== -1 ? raw.slice(exampleIdx + '@example'.length) : '';
  const cleanedExample = exampleRaw.replace(/^\s*\* ?/gm, '').trim();
  const exampleMatch = cleanedExample.match(/```(\w+)\s*\n([\s\S]*?)```/);
  const example = exampleMatch
    ? { lang: exampleMatch[1], code: exampleMatch[2].trim() }
    : null;

  return { description: description || null, access, example };
}

function extractSignature(declContent, componentName) {
  const sigName = `${componentName}Signature`;
  const sigRegex = new RegExp(
    `export interface ${sigName}\\s*\\{([\\s\\S]*?)\\n\\}`,
    'm',
  );
  const match = declContent.match(sigRegex);
  if (!match) return null;

  let sig = match[0]
    .replace(/^export /, '')
    .replace(/Map\$1/g, 'Map')
    .replace(/\/\*\*\s*@internal\s*\*\/\n\s*/g, '')
    .replace(/import\([^)]+\)\./g, '');

  return sig;
}

function parseArgs(declContent, componentName) {
  const sigName = `${componentName}Signature`;
  const sigMatch = declContent.match(
    new RegExp(`export interface ${sigName}\\s*\\{([\\s\\S]*?)\\n\\}`, 'm'),
  );
  if (!sigMatch) return [];

  const body = sigMatch[1];

  // Find the Args block
  const argsMatch = body.match(/Args:\s*\{([\s\S]*?)\n\s{4}\};/);
  if (!argsMatch) return [];

  const argsBody = argsMatch[1];
  const args = [];

  // Parse each property: /** description */ name?: Type;
  // Handle multiline types by matching up to the next JSDoc or end of block
  const propRegex =
    /\/\*\*\s*([\s\S]*?)\s*\*\/\s*\n\s+(\w+)(\??):\s*([\s\S]*?)(?=\n\s+\/\*\*|\n\s*\};|$)/g;
  let m;
  while ((m = propRegex.exec(argsBody)) !== null) {
    const description = m[1]
      .replace(/\s*\*\s*/g, ' ')
      .replace(/@see\s+\S+/g, '')
      .trim();
    const name = m[2];
    const optional = m[3] === '?';
    let type = m[4].replace(/;\s*$/, '').trim();

    // Skip pre-bound args
    if (PREBOUND_ARGS.has(name)) continue;

    // Simplify common types for display
    type = type
      .replace(/maplibregl\./g, '')
      .replace(/Map\$1/g, 'Map')
      .replace(/import\([^)]+\)\./g, '')
      // Multiline cleanup first (before other regexes)
      .replace(/\n\s*/g, ' ')
      // Omit<X, 'id'> & { ... } → X
      .replace(/Omit<(\w+),\s*[^>]+>\s*&\s*\{[^}]*\}/g, '$1')
      // Parameters<Map['method']>['index'] → friendly type names
      .replace(/Parameters<\w+\['addSource'\]>\[['"]?\d['"]?\]/g, 'SourceSpecification')
      .replace(/Parameters<\w+\['addLayer'\]>\[['"]?\d['"]?\]/g, 'string')
      .replace(/Parameters<\w+\['addImage'\]>\[['"]?0['"]?\]/g, 'string')
      .replace(/Parameters<\w+\['addImage'\]>\[['"]?1['"]?\]/g, 'ImageData | HTMLImageElement')
      .replace(/Parameters<\w+\['addImage'\]>\[['"]?2['"]?\]/g, 'ImageOptions')
      .replace(/Parameters<\w+\['loadImage'\]>\[['"]?\d['"]?\]/g, 'string')
      .replace(/Parameters<\w+\['addControl'\]>\[['"]?1['"]?\]/g, 'ControlPosition')
      .replace(/Parameters<[^>]+>\[['"]?\d['"]?\]/g, 'string')
      .replace(/Parameters<[^>]+>/g, 'string')
      // HTMLImageElement['width'] → number
      .replace(/HTMLImageElement\['\w+'\]/g, 'number')
      // new (...args) => T → MapConstructor
      .replace(/new\s*\([^)]*\)\s*=>\s*\w+/g, 'MapConstructor')
      // (map: Map) => void → Function
      .replace(/\([^)]*\)\s*=>\s*void/g, 'Function')
      // (err: unknown) => void → Function
      .replace(/\([^)]*\)\s*=>\s*\w+/g, 'Function')
      .trim();

    // Truncate very long types
    if (type.length > 50) {
      type = type.slice(0, 47) + '...';
    }

    args.push({ name, type, required: !optional, description });
  }

  return args;
}

function parseYields(declContent, componentName) {
  const sigName = `${componentName}Signature`;
  const sigMatch = declContent.match(
    new RegExp(`export interface ${sigName}\\s*\\{([\\s\\S]*?)\\n\\}`, 'm'),
  );
  if (!sigMatch) return [];

  const body = sigMatch[1];

  // Find the Blocks.default array content
  const blocksMatch = body.match(
    /default:\s*\[\s*\{([\s\S]*?)\}\s*\]/,
  );
  if (!blocksMatch) return [];

  const blocksBody = blocksMatch[1];
  const yields = [];

  const propRegex =
    /\/\*\*\s*([\s\S]*?)\s*\*\/\s*\n\s+(\w+):\s*([^;]+);/g;
  let m;
  while ((m = propRegex.exec(blocksBody)) !== null) {
    const description = m[1]
      .replace(/\s*\*\s*/g, ' ')
      .trim();
    const name = m[2];
    let type = m[3].trim();

    // Simplify WithBoundArgs for display
    type = type
      .replace(/WithBoundArgs<typeof (\w+),\s*[^>]+>/g, '$1')
      .replace(/import\([^)]+\)\./g, '')
      .replace(/Map\$1/g, 'Map')
      .replace(/maplibregl\./g, '')
      .trim();

    if (type.length > 50) {
      type = type.slice(0, 47) + '...';
    }

    yields.push({ name, type, description });
  }

  return yields;
}

/**
 * Extract exported type aliases from the declaration file.
 * Returns an array of { name, definition, description, seeUrl }.
 */
function parseExportedTypes(declContent) {
  const types = [];
  // Match: JSDoc block followed by `export type Name = ...;`
  const regex = /(?:\/\*\*\s*([\s\S]*?)\s*\*\/\s*\n)?export type (\w+)\s*=\s*([^;]+);/g;
  let m;
  while ((m = regex.exec(declContent)) !== null) {
    const rawDoc = m[1] || '';
    const name = m[2];
    const definition = m[3].trim();

    // Extract @see URL
    const seeMatch = rawDoc.match(/@see\s+(https?:\S+)/);
    const seeUrl = seeMatch ? seeMatch[1] : null;

    // Clean description: remove @see, @tags, strip comment prefixes
    const description = rawDoc
      .replace(/@see\s+\S+/g, '')
      .replace(/\{@link\s+[^|]*?\|\s*([^}]+)\}/g, '$1')
      .replace(/\{@link\s+(\w+)\}/g, '$1')
      .replace(/^\s*\*\s?/gm, '')
      .trim();

    types.push({ name, definition, description, seeUrl });
  }
  return types;
}

function buildTypeBlock(t) {
  let block = `### ${t.name}\n\n`;
  if (t.description) {
    block += `${t.description}\n\n`;
  }
  block += `\`\`\`ts\ntype ${t.name} = ${t.definition}\n\`\`\`\n`;
  if (t.seeUrl) {
    block += `\n[MapLibre docs \u2192](${t.seeUrl})\n`;
  }
  return block;
}

function buildArgsTable(args, types) {
  if (args.length === 0) return '';
  let table = '## Args\n\n';
  table += '| Arg | Type | Required | Description |\n';
  table += '|-----|------|----------|-------------|\n';
  for (const a of args) {
    const req = a.required ? 'Yes' : 'No';
    const linkedType = linkMapLibreTypes(a.type);
    // Escape pipe characters in type names to avoid breaking markdown tables
    const escapedType = linkedType.replace(/\|/g, '\\|');
    const typeCell = escapedType.includes('[') ? escapedType : `\`${escapedType}\``;
    table += `| \`${a.name}\` | ${typeCell} | ${req} | ${a.description} |\n`;
  }
  // Append type definitions inline below the table
  for (const t of types) {
    table += `\n${buildTypeBlock(t)}`;
  }
  return table;
}

function linkComponentTypes(typeStr) {
  let result = typeStr;
  for (const [name, url] of Object.entries(COMPONENT_DOC_URLS)) {
    const regex = new RegExp(`\\b${name}\\b`, 'g');
    result = result.replace(regex, `[${name}](${url})`);
  }
  return result;
}

function buildYieldsTable(yields) {
  if (yields.length === 0) return '';
  let table = '## Yields\n\n';
  table += '| Property | Type | Description |\n';
  table += '|----------|------|-------------|\n';
  for (const y of yields) {
    let linkedType = linkMapLibreTypes(y.type);
    linkedType = linkComponentTypes(linkedType);
    const typeCell = linkedType.includes('[') ? linkedType : `\`${linkedType}\``;
    table += `| \`${y.name}\` | ${typeCell} | ${y.description} |\n`;
  }
  return table;
}

function getComponentName(declContent) {
  const match = declContent.match(/export default class (\w+)/);
  return match ? match[1] : null;
}

function injectBlock(content, marker, block) {
  const openTag = `<!-- ${marker} -->`;
  const closeTag = `<!-- /${marker} -->`;

  const wrapped = `${openTag}\n${block}\n${closeTag}`;

  if (content.includes(openTag)) {
    return content.replace(
      new RegExp(`${openTag}[\\s\\S]*?${closeTag}`),
      wrapped,
    );
  }

  // Auto-insert before ## Demo if marker not found
  const demoIdx = content.indexOf('## Demo');
  if (demoIdx !== -1) {
    return content.slice(0, demoIdx) + wrapped + '\n\n' + content.slice(demoIdx);
  }
  return content + '\n\n' + wrapped + '\n';
}

for (const [docFile, declFile] of Object.entries(COMPONENT_MAP)) {
  const docPath = join(DOCS_DIR, docFile);
  const declPath = join(DECL_DIR, declFile);

  let docContent;
  try {
    docContent = readFileSync(docPath, 'utf-8');
  } catch {
    console.log(`Skipping ${docFile} (not found)`);
    continue;
  }

  let declContent;
  try {
    declContent = readFileSync(declPath, 'utf-8');
  } catch {
    console.log(`Skipping ${declFile} (declaration not found)`);
    continue;
  }

  const componentName = getComponentName(declContent);
  if (!componentName) {
    console.log(`Skipping ${declFile} (no default export found)`);
    continue;
  }

  // Extract class-level JSDoc (description + example)
  const jsdoc = extractClassJSDoc(declContent, componentName);

  // Extract signature code block
  const signature = extractSignature(declContent, componentName);

  // Parse args, types, and yields
  const exportedTypes = parseExportedTypes(declContent);
  // Set up same-page anchors for this file's types (VitePress lowercases headings)
  ADDON_TYPE_ANCHORS = {};
  for (const t of exportedTypes) {
    ADDON_TYPE_ANCHORS[t.name] = `#${t.name.toLowerCase()}`;
  }
  const args = parseArgs(declContent, componentName);
  const yields = parseYields(declContent, componentName);

  // Inject blocks
  if (jsdoc?.description) {
    docContent = injectBlock(docContent, 'DESCRIPTION', jsdoc.description);
  }

  if (jsdoc?.example) {
    const exampleBlock = `## Example\n\n\`\`\`${jsdoc.example.lang}\n${jsdoc.example.code}\n\`\`\``;
    docContent = injectBlock(docContent, 'EXAMPLE', exampleBlock);
  }

  if (jsdoc?.access) {
    // Look up the direct import path from COMPONENT_MAP
    const importName = componentName;
    const importPath = `ember-maplibre-gl/components/${declFile.replace('.d.ts', '')}`;
    const importBlock = `## Import\n\nYielded by ${jsdoc.access} — no import needed.\n\n::: details Direct import (rare)\n\`\`\`ts\nimport ${importName} from '${importPath}';\n\`\`\`\n:::`;
    docContent = injectBlock(docContent, 'IMPORT', importBlock);
  }

  if (signature) {
    const sigBlock = `## Signature\n\n\`\`\`ts\n${signature}\n\`\`\``;
    docContent = injectBlock(docContent, 'SIGNATURE', sigBlock);
  }

  if (args.length > 0) {
    docContent = injectBlock(docContent, 'ARGS', buildArgsTable(args, exportedTypes));
  }

  // Remove stale standalone TYPES block if it exists from a previous run
  docContent = docContent.replace(/\n*<!-- TYPES -->[\s\S]*?<!-- \/TYPES -->\n*/g, '\n');

  if (yields.length > 0) {
    docContent = injectBlock(docContent, 'YIELDS', buildYieldsTable(yields));
  }

  writeFileSync(docPath, docContent);
  console.log(
    `Updated ${docFile}: desc=${!!jsdoc?.description}, example=${!!jsdoc?.example}, import=${!!jsdoc?.access}, signature=${!!signature}, args=${args.length} (types=${exportedTypes.length}), yields=${yields.length}`,
  );
}
