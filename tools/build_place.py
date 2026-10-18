#!/usr/bin/env python3
"""Build a portable Roblox XML place from the Rojo tree using Python's stdlib.

No plugin, Roblox credentials, third-party models, or binary dependencies needed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def item(parent, class_name, name, counter):
    counter[0] += 1
    node = ET.SubElement(parent, 'Item', {'class': class_name, 'referent': f'RBX{counter[0]}'} )
    properties = ET.SubElement(node, 'Properties')
    ET.SubElement(properties, 'string', {'name': 'Name'}).text = name
    return node, properties


def add_source(parent, source, counter):
    if source.name.endswith('.server.luau'):
        class_name, name = 'Script', source.name.removesuffix('.server.luau')
    elif source.name.endswith('.client.luau'):
        class_name, name = 'LocalScript', source.name.removesuffix('.client.luau')
    else:
        class_name, name = 'ModuleScript', source.stem
    _, properties = item(parent, class_name, name, counter)
    ET.SubElement(properties, 'ProtectedString', {'name': 'Source'}).text = source.read_text(encoding='utf-8')
    if class_name != 'ModuleScript':
        ET.SubElement(properties, 'bool', {'name': 'Disabled'}).text = 'false'


def add_property(properties, name, value):
    if isinstance(value, bool):
        ET.SubElement(properties, 'bool', {'name': name}).text = str(value).lower()
    elif isinstance(value, str):
        ET.SubElement(properties, 'string', {'name': name}).text = value
    elif isinstance(value, (int, float)):
        tag = 'int' if name in {'DisplayOrder', 'ZIndex', 'BorderSizePixel'} else 'float'
        ET.SubElement(properties, tag, {'name': name}).text = str(value)
    elif isinstance(value, dict) and set(value) == {'UDim2'}:
        node = ET.SubElement(properties, 'UDim2', {'name': name})
        x, y = value['UDim2']
        for key, component in zip(('XS', 'XO', 'YS', 'YO'), (*x, *y)):
            ET.SubElement(node, key).text = str(component)
    elif isinstance(value, dict) and set(value) == {'Color3'}:
        node = ET.SubElement(properties, 'Color3', {'name': name})
        for key, component in zip(('R', 'G', 'B'), value['Color3']):
            ET.SubElement(node, key).text = str(component)
    else:
        raise ValueError(f'Unsupported project property: {name} = {value!r}')


def build(destination):
    project = json.loads((ROOT / 'default.project.json').read_text())
    root = ET.Element('roblox', {'version': '4'})
    ET.SubElement(root, 'External').text = 'null'
    ET.SubElement(root, 'External').text = 'nil'
    counter = [0]
    services = {'ReplicatedStorage', 'ServerScriptService', 'StarterPlayer', 'StarterPlayerScripts', 'StarterGui'}

    def traverse(parent, name, description):
        class_name = description.get('$className', name if name in services else 'Folder')
        node, properties = item(parent, class_name, name, counter)
        for property_name, value in description.get('$properties', {}).items():
            add_property(properties, property_name, value)
        if '$path' in description:
            directory = ROOT / description['$path']
            for path in sorted(directory.iterdir()):
                if path.suffix == '.luau':
                    add_source(node, path, counter)
                elif path.is_dir():
                    raise ValueError(f'Nested source directories need an explicit project entry: {path}')
        for child_name, child in description.items():
            if not child_name.startswith('$'):
                traverse(node, child_name, child)

    for name, description in project['tree'].items():
        if not name.startswith('$'):
            traverse(root, name, description)
    _, workspace_properties = item(root, 'Workspace', 'Workspace', counter)
    ET.SubElement(workspace_properties, 'bool', {'name': 'StreamingEnabled'}).text = 'false'
    _, lighting_properties = item(root, 'Lighting', 'Lighting', counter)
    ET.SubElement(lighting_properties, 'float', {'name': 'ClockTime'}).text = '14'
    item(root, 'SoundService', 'SoundService', counter)
    ET.indent(root, space='  ')
    destination.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(destination, encoding='utf-8', xml_declaration=True)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix('.rbxlx.sha256').write_text(f'{digest}  {destination.name}\n')
    print(f'Built {destination} ({destination.stat().st_size:,} bytes)')
    return root


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/CloudpopCommons.rbxlx')
    build(parser.parse_args().output)
