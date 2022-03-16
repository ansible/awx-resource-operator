'''
After generating the bundle, inject custom configuration for annotations.
'''

import yaml

annotations_path = "../../../bundle/metadata/annotations.yaml"
existing_annotations = open(annotations_path, 'r')
annotations = yaml.safe_load(existing_annotations)


raw_annotations = open("annotations.yaml")
base_annotations = yaml.safe_load(raw_annotations)

# Inject custom annotations
annotations['annotations'].update(base_annotations['annotations'])

file_content = yaml.safe_dump(annotations, default_flow_style=False, explicit_start=True)

with open(annotations_path, 'w') as f:
    f.write(file_content)
