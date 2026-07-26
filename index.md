---
layout: default
title: "OrbitBits Packages"
---

{% assign packages = site.data.generic.packages %}

# {{ packages.title }}

{{ packages.description }}

{% for repository in packages.repositories %}
## {{ repository.name }}

[Browse repository]({{ repository.path | relative_url }})
{% if repository.config %}
[Client configuration]({{ repository.config | relative_url }})
{% endif %}

{% for metadata in repository.metadata %}
- [{{ metadata }}]({{ metadata | relative_url }})
{% endfor %}
{% endfor %}

## Signing Key

[Download OrbitBits public key]({{ packages.key_url }})
