import importlib
import types
import inspect
import os
import sys

import sage.all

# Cache for imported modules to avoid re-importing
_imported_modules = {}

def sage_import(modname, fromlist=None, namespace=None):
    """
    Import a .sage module from the filename <modname>.sage

    Handles recursive imports and avoids re-importing the same file multiple times.

    Returns the resulting Python module. If ``fromlist`` is given, returns
    just those members of the module into the global namespace where the
    function was called, or the given namespace.
    """
    global _imported_modules

    filename = modname + '.sage'

    # Resolve the absolute path of the module file
    for path in sys.path:
        modpath = os.path.abspath(os.path.join(path, filename))
        if os.path.isfile(modpath):
            break
    else:
        raise ImportError(f'No file {filename} on sys.path')

    # If the module is already imported, return it from the cache
    if modpath in _imported_modules:
        mod = _imported_modules[modpath]
    else:
        # Read and preparse the .sage file
        with open(modpath) as fobj:
            code = sage.all.preparse(fobj.read())

        # Create a module object and populate it with Sage globals
        mod = types.ModuleType(modname)
        mod.__file__ = modpath
        for k, v in sage.all.__dict__.items():
            if not k.startswith('_'):
                mod.__dict__[k] = v

        # Update sys.path temporarily to handle recursive imports
        current_dir = os.path.dirname(modpath)
        original_sys_path = sys.path[:]
        sys.path.insert(0, current_dir)

        try:
            # Execute the pre-parsed code within the module's namespace
            exec(code, mod.__dict__)
        finally:
            sys.path = original_sys_path

        # Cache the module to avoid re-importing
        _imported_modules[modpath] = mod

    # Handle namespace and fromlist
    if namespace is None:
        namespace = inspect.currentframe().f_back.f_globals

    if fromlist is not None:
        # Ensure all requested names exist in the module
        for name in fromlist:
            if name not in mod.__dict__:
                raise ImportError(f'Cannot import name {name!r} from {filename}')
        # Add requested names to the namespace
        for name in fromlist:
            namespace[name] = mod.__dict__[name]
    else:
        # Add the entire module to the namespace
        namespace[modname] = mod

'''
def sage_import(modname, fromlist=None, namespace=None):
    """
    Import a .sage module from the filename <modname>.sage

    Returns the resulting Python module.  If ``fromlist`` is given, returns
    just those members of the module into the global namespace where the
    function was called, or the given namespace.
    """

    filename = modname + '.sage'

    for path in sys.path:
        modpath = os.path.join(path, filename)
        if os.path.isfile(modpath):
            break
    else:
        raise ImportError('no file {} on sys.path'.format(filename))

    with open(modpath) as fobj:
        code = sage.all.preparse(fobj.read())
        mod = types.ModuleType(modname)
        mod.__file__ = modpath
        # Fill with all the default Sage globals
        # We could just do a dict.update but we want to exclude dunder
        # and private attributes I guess
        for k, v in sage.all.__dict__.items():
            if not k.startswith('_'):
                mod.__dict__[k] = v

        exec(code, mod.__dict__)

    if namespace is None:
        namespace = inspect.currentframe().f_back.f_globals


    if fromlist is not None:
        # First check that each name in fromlist exists before adding
        # any of them to the given namespace.
        for name in fromlist:
            if name not in mod.__dict__:
                raise ImportError('cannot import name {!r} from {}'.format(
                     name, filename))

        for name in fromlist:
            namespace[name] = mod.__dict__[name]
    else:
        namespace[modname] = mod

'''