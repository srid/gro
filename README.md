# gro

I want a way to process and visualize the contents of my single `.org` file.

## tasks

- [x] add org-parser dep, parse `one.org`, and dump in `<tt>`
  - https://github.com/lucasvreis/org-mode-hs
- [ ] basic HTML rendering
- [ ] basic queries
  - Keep GTD (à la Things) in mind.

## ideas

### query 

A special org heading can register queries that are 'expanded' on the web view with results. 

Thus, there is no dynamism on the web view, in line with [Ema](https://ema.srid.ca/)'s philosophy.

### routes

A single `.org` file is read for simplicity. Thus, each heading can be reached via their own route (if required). This is useful for auto-reloading previews ([inside xwidgets](https://twitter.com/sridca/status/1604490544402632705), notably) of the requested section.
