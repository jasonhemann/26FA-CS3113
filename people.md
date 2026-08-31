---
title: People
layout: collection
collection: people
---

| Name | Role | Contact | Office Hours |
|------|------|---------|--------------|
| {{ site.author.name }} | Instructor | [{{ site.author.email }}](mailto:{{ site.author.email }}) | {{ site.author.office_hours | default: "" }} |
{% for person in site.data.personnel %} | {{ person.name }} | {{ person.role | default: "" }} | {% if person.email %}[{{ person.email }}](mailto:{{ person.email }}){% endif %} | {{ person.office_hours | default: "" }} |
{% endfor %}

![Logical Distortion]({{ site.baseurl }}/assets/images/aura-of-logical-distortion.gif "Sometimes it helps just having someone else around")
