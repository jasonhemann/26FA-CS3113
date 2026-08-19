# Course Website Template

Course site built with Jekyll (GitHub Pages toolchain) and based on Minimal Mistakes.

## Required Toolchain

For local development and testing, install:

1. Ruby (see [`.ruby-version`](.ruby-version))
2. Bundler
3. Git

Optional, only if you need syllabus PDF output:

1. Pandoc
2. A LaTeX engine (for example MacTeX/TeX Live, used by Pandoc when writing PDF)

## Local Setup

Install Ruby dependencies:

```bash
bundle install
```

Build the site once:

```bash
bundle exec jekyll build
```

(In some shell environments, you might need `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bundle exec jekyll build`.)

Run locally with live reload:

```bash
bundle exec jekyll serve --livereload
```

Then open: `http://127.0.0.1:4000/course-site-template/`

## Contributor Workflow

### 1) Update site author / people-page information

A common contributor task is updating the People page. That data lives in [`_data/personnel.yml`](_data/personnel.yml), and the page is rendered from [`people.md`](people.md).

Each entry should include:

- `name`
- `role` (for example `Instructor`, `TA`, `Tutor`, `Grader`)
- `email` (or leave blank)
- `email_link` (typically `mailto:...`, or leave blank)
- `office_hours` (or leave blank)

The general contributor loop is: update the source data, run the site locally, and review the rendered page.

### 2) Update syllabus content

Primary syllabus source: [`syllabus.md`](syllabus.md)

Typical loop:

1. Edit `syllabus.md`
2. Run `bundle exec jekyll serve --livereload`
3. Review `http://127.0.0.1:4000/course-site-template/syllabus/`

If you need PDF output:

```bash
./syllabus_prebuild.rb
pandoc syllabus_rendered.md --metadata-file=_config.yml -o syllabus.pdf
```

### 3) Update schedule and related course content

Schedule data lives in [`_data/schedule.yml`](_data/schedule.yml), and the page template is [`schedule.md`](schedule.md).

Typical loop:

1. Edit `_data/schedule.yml`
2. Run local server (`bundle exec jekyll serve --livereload`)
3. Review `http://127.0.0.1:4000/course-site-template/schedule/`

## Notes

- The local Ruby/Jekyll toolchain is pinned in [`Gemfile`](Gemfile), [`Gemfile.lock`](Gemfile.lock), and [`.ruby-version`](.ruby-version).
- This template uses [`_data/authors.yml`](_data/authors.yml) for site author metadata; keep that file for instructor/sidebar metadata.
- The first `jekyll serve` on a new machine needs internet access to download the remote theme.
