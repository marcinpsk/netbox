# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NetBox is a Django-based network infrastructure management application (IPAM/DCIM). Python 3.12+, Django 5.2, PostgreSQL only, Redis required for caching and task queuing.

## Key Commands

All commands run from the **repo root**. Note that `manage.py` lives at `netbox/manage.py`, not the repo root.

### Testing (requires running PostgreSQL + Redis)
```bash
# Run all tests
NETBOX_CONFIGURATION=netbox.configuration_testing python netbox/manage.py test netbox/ --parallel

# Run single app tests
NETBOX_CONFIGURATION=netbox.configuration_testing python netbox/manage.py test netbox/dcim/

# Run single test class
NETBOX_CONFIGURATION=netbox.configuration_testing python netbox/manage.py test netbox/dcim.tests.test_views.SiteTestCase

# Run single test method
NETBOX_CONFIGURATION=netbox.configuration_testing python netbox/manage.py test netbox/dcim.tests.test_views.SiteTestCase.test_get_object_with_permission
```

The `NETBOX_CONFIGURATION=netbox.configuration_testing` env var is **required** for tests. The testing config expects PostgreSQL database `netbox` with user/password `netbox/netbox` on localhost, and Redis on localhost:6379.

### Linting
```bash
ruff check netbox/                              # Python linting
yarn --cwd netbox/project-static validate       # Frontend (ESLint + TypeScript + Prettier)
```

### Migrations
```bash
python netbox/manage.py makemigrations          # Create migrations
python netbox/manage.py makemigrations --check  # Verify none are missing (CI check)
```

### Frontend
```bash
yarn --cwd netbox/project-static                # Install dependencies
yarn --cwd netbox/project-static bundle         # Build static assets
```

Compiled bundles in `project-static/dist/` are committed to git. After modifying frontend source, run `yarn bundle` and commit the output.

### Dev Server
Requires `netbox/netbox/configuration.py` (copy from `configuration_example.py`).
```bash
python netbox/manage.py runserver
```

## Architecture

### Django Apps

| App | Purpose |
|-----|---------|
| `dcim` | Sites, racks, devices, cables, interfaces, power, modules (largest app) |
| `ipam` | IP addresses, prefixes, VLANs, VRFs, ASNs, FHRP groups |
| `circuits` | Network circuits, providers, provider accounts |
| `virtualization` | Virtual machines, clusters, VM interfaces |
| `vpn` | Tunnels, IKE/IPSec policies, L2VPN |
| `wireless` | Wireless LANs, wireless links |
| `tenancy` | Tenants, tenant groups, contacts |
| `extras` | Custom fields, tags, webhooks, scripts, export templates, config contexts |
| `core` | Data sources, jobs, change logging, background tasks |
| `users` | Users, groups, tokens, object permissions |
| `account` | Current user profile, preferences, login/logout |
| `utilities` | Shared utilities, base test classes, template tags |

### Per-App Code Organization

Each app follows a consistent structure:
- `models/` — Django models (split across multiple files, re-exported via `__init__.py`)
- `forms/` — `model_forms.py`, `bulk_edit.py`, `bulk_import.py`, `filtersets.py`
- `tables/` — django-tables2 table definitions
- `filtersets.py` — django-filter FilterSet classes
- `api/` — DRF ViewSets + serializers (REST API at `/api/<app>/`)
- `graphql/` — Strawberry types + filters (GraphQL at `/graphql/`)
- `ui/` — Declarative UI panel definitions (newer pattern using attrs)
- `views.py` — View classes using `@register_model_view` decorator
- `choices.py` — ChoiceSet enum definitions
- `search.py` — Search index definitions
- `tests/` — `test_api.py`, `test_views.py`, `test_filtersets.py`, `test_forms.py`, `test_models.py`

### Model Hierarchy

Base classes in `netbox/netbox/models/__init__.py`:
- `PrimaryModel` — Main infrastructure objects (devices, sites, prefixes, etc.). Has custom fields, tags, comments, journaling, bookmarks, owner.
- `OrganizationalModel` — Categorization objects (device roles, regions). Has name, slug, description.
- `NestedGroupModel` — Hierarchical objects using MPTT (regions, locations, tenant groups).
- All models use `RestrictedQuerySet` as default manager, enforcing object-level permissions via `.restrict(user, action)`.

### View Registration Pattern

Views use `@register_model_view` decorator instead of traditional URLconfs:
```python
@register_model_view(Site, 'list', path='', detail=False)
class SiteListView(generic.ObjectListView):
    ...
```
The `urls.py` files call `get_model_urls()` to resolve registered views.

### Test Framework

Uses Django's `TestCase` (not pytest). Base classes in `utilities/testing/`:
- `ViewTestCases.PrimaryObjectViewTestCase` — Combines all UI CRUD tests
- `ViewTestCases.OrganizationalObjectViewTestCase` — For organizational models
- `APIViewTestCases.APIViewTestCase` — Combines all REST API CRUD tests

Test mixins are **nested inside** `ViewTestCases`/`APIViewTestCases` classes to prevent unittest from discovering them directly. Concrete test classes inherit from these and set `model = SomeModel`.

### Plugin System

Plugins extend `PluginConfig` from `netbox.plugins`, declared in configuration under `PLUGINS`. A dummy plugin at `netbox/netbox/tests/dummy_plugin/` is loaded during tests.

## Code Style

- **Line length**: 120
- **Quotes**: Single quotes
- **Linter**: Ruff (F403/F405 suppressed — star imports are intentional)
- **Formatter**: Black-compatible (line-length 120, skip-string-normalization)
