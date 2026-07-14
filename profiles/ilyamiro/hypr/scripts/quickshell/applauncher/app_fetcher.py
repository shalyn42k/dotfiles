#!/usr/bin/env python3
import os
import glob
import json
import subprocess

def fetch_apps():
    apps = {}
    home = os.path.expanduser('~')
    
    # Expanded directories to catch Flatpaks, system apps, and Nix packages
    dirs = [
        '/usr/share/applications',
        '/usr/local/share/applications',
        f'{home}/.local/share/applications',
        '/var/lib/flatpak/exports/share/applications',
        f'{home}/.local/share/flatpak/exports/share/applications',
        f'{home}/.nix-profile/share/applications',
        '/run/current-system/sw/share/applications'
    ]
    
    for d in dirs:
        if not os.path.exists(d):
            continue
            
        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
            try:
                with open(f, 'r', encoding='utf-8') as file:
                    app = {'name': '', 'exec': '', 'icon': ''}
                    is_desktop = False
                    no_display = False
                    
                    for line in file:
                        line = line.strip()
                        if line == '[Desktop Entry]':
                            is_desktop = True
                        elif line.startswith('['):
                            is_desktop = False
                            
                        if is_desktop:
                            if line.startswith('Name=') and not app['name']:
                                app['name'] = line[5:]
                            elif line.startswith('Exec=') and not app['exec']:
                                # Strip %u, %f, and @@ placeholders
                                app['exec'] = line[5:].split(' %')[0].split(' @@')[0]
                            elif line.startswith('Icon=') and not app['icon']:
                                app['icon'] = line[5:]
                            elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
                                no_display = True
                                
                    if app['name'] and app['exec'] and not no_display:
                        apps[app['name']] = app
            except Exception:
                pass
                
    # QIcon::fromTheme (image://icon/ in QML) only searches the configured
    # icon theme's inheritance chain — icons living in other themes or in
    # /usr/share/pixmaps come out broken. Resolve those to absolute paths,
    # which the QML side already handles via file://.
    icon_bases = ('/usr/share/icons', f'{home}/.local/share/icons', f'{home}/.icons')

    def theme_chain(theme):
        chain, todo = [], [theme]
        while todo:
            t = todo.pop(0)
            if not t or t in chain:
                continue
            for base in icon_bases:
                index = os.path.join(base, t, 'index.theme')
                if not os.path.isdir(os.path.join(base, t)):
                    continue
                chain.append(t)
                try:
                    with open(index, encoding='utf-8', errors='replace') as fh:
                        for line in fh:
                            if line.startswith('Inherits='):
                                todo += [i.strip() for i in line[9:].split(',')]
                                break
                except OSError:
                    pass
                break
        if 'hicolor' not in chain:
            chain.append('hicolor')
        return chain

    theme = 'hicolor'
    try:
        with open(f'{home}/.config/qt6ct/qt6ct.conf', encoding='utf-8') as fh:
            for line in fh:
                if line.startswith('icon_theme='):
                    theme = line.split('=', 1)[1].strip()
                    break
    except OSError:
        pass

    # find -L: C-speed enumeration, follows Papirus-Dark's symlinked dirs
    theme_dirs = [os.path.join(base, t)
                  for t in theme_chain(theme) for base in icon_bases
                  if os.path.isdir(os.path.join(base, t))]
    out = subprocess.run(['find', '-L', *theme_dirs, '-type', 'f', '-printf', '%f\n'],
                         capture_output=True, text=True).stdout
    reachable = {os.path.splitext(fn)[0] for fn in out.splitlines()}

    def resolve(name):
        # pixmaps first: cheap and covers the common case
        for ext in ('svg', 'png', 'xpm'):
            p = f'/usr/share/pixmaps/{name}.{ext}'
            if os.path.exists(p):
                return p
        # fall back to any installed theme (find is far cheaper than glob here)
        out = subprocess.run(
            ['find', '-L', *[b for b in icon_bases if os.path.isdir(b)],
             '-type', 'f', '(', '-name', f'{name}.svg', '-o', '-name', f'{name}.png', ')',
             '-print', '-quit'],
            capture_output=True, text=True).stdout.strip()
        return out or None

    for app in apps.values():
        icon = app['icon']
        if icon and not icon.startswith('/') and icon not in reachable:
            app['icon'] = resolve(icon) or icon

    # Sort alphabetically and return as JSON
    res = list(apps.values())
    res.sort(key=lambda x: x['name'].lower())
    print(json.dumps(res))

if __name__ == "__main__":
    fetch_apps()


