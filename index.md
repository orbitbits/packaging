---
layout: default
title: "OrbitBits Packages"
---

{% assign packages = site.data.generic.packages %}

# {{ packages.title }}

<p class="lead text-muted">{{ packages.description }}</p>

<div class="row g-4 mt-2">
{% for repository in packages.repositories %}
  <div class="col-12 col-lg-6">
    <section class="repository-panel h-100">
      <div class="d-flex align-items-center justify-content-between gap-3 mb-3">
        <h2 class="h4 mb-0">{{ repository.name }}</h2>
        <a class="btn btn-outline-primary btn-sm" href="{{ repository.path | relative_url }}">
          Browse
        </a>
      </div>

      {% if repository.config %}
        <p class="mb-3">
          <a href="{{ repository.config | relative_url }}">Client configuration</a>
        </p>
      {% endif %}

      <ul class="list-unstyled mb-0">
        {% for metadata in repository.metadata %}
          <li class="mb-2">
            <a href="{{ metadata | relative_url }}"><code>{{ metadata }}</code></a>
          </li>
        {% endfor %}
      </ul>
    </section>
  </div>
{% endfor %}
</div>

## Signing Key

<p><a class="btn btn-primary" href="{{ packages.key_url }}">Download OrbitBits public key</a></p>
