"""
Tutor plugin: Campus main menu in the Open edX MFE headers.

- Replaces the default main menu ("Courses", "Programs", ...) with links to the
  learner dashboard and the public Campus site (cursos, eventos).
- Staff users (`is_staff`) also see "Administración" (Campus admin).
- Desktop and mobile headers, plus the course header of the `learning` MFE.

The menu is compiled into the MFE image, so after changing it:
    tutor images build mfe && tutor dev restart mfe

The JS uses aliased imports and `createElement` instead of JSX so it does not
clash with (or depend on) the identifiers that tutor-indigo imports.
"""
from tutor import hooks
from tutormfe.hooks import PLUGIN_SLOTS

hooks.Filters.CONFIG_DEFAULTS.add_items(
    [
        # Public (Nuxt) site the menu links to.
        ("CAMPUS_MENU_SITE_URL", "http://www.local.openedx.io:3000"),
    ]
)

hooks.Filters.ENV_PATCHES.add_items(
    [
        (
            "mfe-env-config-buildtime-imports",
            """
import { createElement as campusH, useContext as campusUseContext } from 'react';
import { getConfig as campusGetConfig } from '@edx/frontend-platform';
import { AppContext as CampusAppContext } from '@edx/frontend-platform/react';
""",
        ),
        (
            "mfe-env-config-buildtime-definitions",
            """
const campusMenuLinks = (user) => {
  const site = '{{ CAMPUS_MENU_SITE_URL }}'.replace(/\\/$/, '');
  const links = [
    { id: 'dashboard', label: 'Mis cursos', href: `${campusGetConfig().LMS_BASE_URL}/dashboard` },
    { id: 'cursos', label: 'Cursos', href: `${site}/cursos` },
    { id: 'eventos', label: 'Eventos', href: `${site}/eventos` },
  ];
  if (user && user.administrator) {
    links.push({ id: 'admin', label: 'Administración', href: `${site}/admin` });
  }
  return links;
};

const CampusMenuLinks = ({ className }) => {
  const { authenticatedUser } = campusUseContext(CampusAppContext);
  return campusH(
    'nav',
    { 'aria-label': 'Main', className },
    campusMenuLinks(authenticatedUser).map((link) => campusH(
      'a',
      { key: link.id, className: 'nav-link', href: link.href },
      link.label,
    )),
  );
};

const CampusMainMenu = () => campusH(CampusMenuLinks, { className: 'nav main-nav' });

const CampusMobileMainMenu = () => campusH(CampusMenuLinks, { className: 'nav flex-column' });

const CampusLearningMenu = () => campusH(CampusMenuLinks, { className: 'nav d-none d-md-flex mr-2' });

// tutor-indigo replaces the whole mobile header with just the logo, so the
// mobile main menu slot never renders there: this adds a collapsible menu.
// Indigo's logo has no header wrapper around it, so the menu is pinned to the
// top-right corner of the page, next to the logo.
const CampusMobileHeaderMenu = () => campusH(
  'details',
  { className: 'campus-mobile-menu' },
  campusH('style', null, `
    .campus-mobile-menu { position: absolute; top: .75rem; right: 1rem; z-index: 1000; }
    .campus-mobile-menu > summary {
      cursor: pointer; list-style: none; padding: .375rem .75rem;
      border: 1px solid currentColor; border-radius: .375rem;
    }
    .campus-mobile-menu > summary::-webkit-details-marker { display: none; }
    .campus-mobile-menu > nav {
      position: absolute; top: calc(100% + .25rem); right: 0; min-width: 12rem;
      background: var(--pgn-color-light-100, #fff);
      box-shadow: 0 .25rem .75rem rgba(0, 0, 0, .15);
    }
  `),
  campusH('summary', null, 'Menú'),
  campusH(CampusMenuLinks, { className: 'nav flex-column' }),
);
""",
        ),
    ]
)


def _replace_slot(mfe: str, slot: str, widget_id: str, component: str) -> list[tuple[str, str, str]]:
    return [
        (mfe, slot, "{ op: PLUGIN_OPERATIONS.Hide, widgetId: 'default_contents' }"),
        (
            mfe,
            slot,
            f"""
            {{
              op: PLUGIN_OPERATIONS.Insert,
              widget: {{ id: '{widget_id}', type: DIRECT_PLUGIN, RenderWidget: {component} }},
            }}""",
        ),
    ]


def _insert_into_slot(mfe: str, slot: str, widget_id: str, component: str) -> tuple[str, str, str]:
    return (
        mfe,
        slot,
        f"""
        {{
          op: PLUGIN_OPERATIONS.Insert,
          widget: {{ id: '{widget_id}', type: DIRECT_PLUGIN, priority: 90, RenderWidget: {component} }},
        }}""",
    )


PLUGIN_SLOTS.add_items(
    [
        *_replace_slot("all", "desktop_main_menu_slot", "campus_main_menu", "CampusMainMenu"),
        *_replace_slot("all", "mobile_main_menu_slot", "campus_mobile_main_menu", "CampusMobileMainMenu"),
        # Course pages use the learning header, which has no main menu slot.
        _insert_into_slot("learning", "learning_help_slot", "campus_learning_menu", "CampusLearningMenu"),
        # MFEs where tutor-indigo replaces the mobile header (see CampusMobileHeaderMenu).
        *[
            _insert_into_slot(mfe, "mobile_header_slot", "campus_mobile_header_menu", "CampusMobileHeaderMenu")
            for mfe in ["learner-dashboard", "profile", "account"]
        ],
    ]
)
