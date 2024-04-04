(local {: hide-display-numbers} (require :spacehammer.windows))

;; A set of functions for adding new submenus and actions to the spacehammer modal, along
;; with their keybindings, "a la carte": i.e. without having to manually maintain a large,
;; nested data structure.

;; we who are about to be mutated salute you
(local config {:title "Main Menu"
               :items []
               :keys []
               :enter hide-display-numbers
               :exit  hide-display-numbers
               :apps []})

;; TODO auto-shift capitals, i.e. "aB" -> [{:key :a} {:key :b :mods [:shift]}]
(fn normalize-key-path [key-path-string-or-table]
  "Returns a normalized key path. A normalized key path is a list of key objects, where
  each is a table defining a key stroke; for example [{:key :a} {:key :c :mods [:ctrl]}]
  for 'a' followed by 'C-c'.

`key-path-string-or-table' can either be a string or a list containing key objects and/or
strings. Strings will be split character by character, with each being wrapped in a key
object; for example 'abc' becomes [{:key :a} {:key :b} {:key :c}]; because of this,
keys which are not unmodified alphanumeric characters can only be represented with key
objects (for example, {:key :space} or {:key :c :mods [:cmd :ctrl]})."
  (fn normalize [key-path acc]
    (case (type key-path)
      :string (each [s (string.gmatch key-path ".")] (table.insert acc {:key s}))
      :table (case key-path
               {:key k} (table.insert acc key-path)
               [_] (each [_ key (ipairs key-path)] (normalize key acc))))
    acc)
  (normalize key-path-string-or-table []))

(fn empty-default-submenu [{: key : mods}]
  "Returns a new instance of an empty menu, suitable for dynamically inserting into an
  undefined intermediary key in a longer menu! or action! prefix."
  {:title "+prefix"
   : key
   : mods
   :items []})

(fn same-keybind? [a b]
  "Predicate for identical keybinds for a menu item (submenu or action). Arguments with
matching :key and :mods values return true."
  (and (= a.key b.key)
       (= (and a.mods (table.unpack a.mods))
          (and b.mods (table.unpack b.mods)))))

(fn find-or-create-submenu [key-object parent-menu ?prev-idx]
  "Returns a menu object in `parent-menu' at the key defined in `key-object', or errors if
an action is already defined for that key. If the requested submenu already exists, it
will be returned directly; if the requested submenu does not exist, a empty default
submenu will be created, inserted into `parent-menu', and returned."
  (match (next parent-menu.items ?prev-idx)
    ;; already an action there? straight to jail.
    (where (idx {: key : mods :action _})
           (same-keybind? {: key : mods} key-object)) (error "A submenu cannot be defined at a keypath which contains an action")
    ;; found it
    (where (idx menu-node)
           (same-keybind? menu-node key-object)) menu-node
    ;; if at first you don't succeed, try try again
    (idx menu-node) (find-or-create-submenu key-object parent-menu idx)
    ;; if at last you don't succeed, make a new empty submenu at the given key
    nil (let [new-submenu (empty-default-submenu key-object)]
          (table.insert parent-menu.items new-submenu)
          new-submenu)))

(fn find-or-create-parent-menu [prefix-key-path]
  "Given a normalized key-path `prefix-key-path', walks the config object and returns the
submenu at the final key of `prefix-key-path'. Any missing submenus will be created on the
fly; if any action is encountered within `prefix-key-path', an error will be raised.

Assumes that `prefix-key-path' is the full intended path of the parent menu: calling code
using this to ensure that an appropriate parent menu is defined for some action or submenu
is responsible for providing only the parent menu's segment of the key-path."
  (var parent-menu config)
  (each [_ key (ipairs prefix-key-path)]
    (let [next-parent (find-or-create-submenu key parent-menu)]
      (set parent-menu next-parent)))
  parent-menu)

(fn separate-out-last-item [list]
  "Returns two values: the first being a new list with every item from `list' except the
last one, and the second being that last item."
  (let [len (length list)]
    (values (icollect [idx item (ipairs list)] (if (not= idx len) item))
            (. list len))))

(fn set-normalized-menu [key-path title options]
  "Defines or renames a new menu item within `config', at `key-path'. Any intermediary menus in `key-path'
  which do not already exist will be created with the default title of `+prefix'."
  (let [(prefix-key-path key-object) (separate-out-last-item key-path)
        parent-menu (find-or-create-parent-menu prefix-key-path)
        menu (find-or-create-submenu key-object parent-menu)]
    (tset menu :title title)
    (if options
        (each [key value (pairs options)]
          (tset menu key value)))
    menu))

(fn menu! [keys title options]
  "Define a (possibly nested) menu in the pop-up modal interface. If the menu does not exist, it will be created; if it does, it will be modified based on your provided definition.

For the top-level menu, use an empty string for `keys`; for deeply nested
menus, provide the entire set of prefix keys required to access the menu. For
example, if there is a menu with keys `a` and another directly nested inside
at the keys `as`,  nesting a third inside the inner menu would require a three-
letter prefix matching the regex /as./. Any nonexistent intermediary submenus will be created with the default title, `+prefix`.

The `options` argument accepts a table for other table options like `:enter` and `:exit`."
  (set-normalized-menu (normalize-key-path keys) title options))

(fn action! [keys title action]
  "Define a new action within the popup modal interface.

The `keys` argument accepts either a string (e.g. for an action bound to `k` within a submodal bound to `as`, the `keys` argument should be the string `ask`; any missing menus will be automatically created) or a list, which can contain either strings or tables (e.g. for a sibling action bound to Command-g, the `keys` argument should be `[:a :s {:mods [:cmd] :key :g}]`). Optionally, you can define a custom title for the action in its containing menu."
  :unimplemented)

;; export for use in other files
{: menu!
 : action!
 : config
 : normalize-key-path}
