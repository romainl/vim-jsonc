# VIM-JSONC

Parse JSONC file in vimscript.

## Background

Files like `tsconfig.json` and `jsconfig.json` have become pretty ubiquitous in TypeScript/JavaScript projects in recent years. A `tsconfig.json` can contain all kinds of useful metada about the project, like paths or aliases, that can be leveraged by custom plugins to enhance file search, go to definition, etc.

Vim has `:help json-decode()` for (loosely) parsing JSON strings but those config files are not actually JSON. They are JSONC, a superset of JSON that allows comments and unquoted keys, which makes `json-decode()` useless despite its rather permissive nature.

Moreover, `tsconfig.json` files can "extend" other files, so we must be able to parse JSONC files recursively.

## Desired features and current status

- TODO -- be generic
- DONE -- parse JSONC files recursively
- DOING -- handle block and inline comments
- TODO -- handle unquoted keys

## Testing

1. Bootstrap an Astro project:

   ```
   $ npm create astro@latest
   ```

2. Replace the content of `tsconfig.json` with the following:

   ```
   /* dsdgfisd
    */ sdgfrsudtyr

    /*
    sdftyusrdtsid
    */

    /*
    * sdftyusrdtsid
    */

    /*
    sdftyusrdtsid
    */

    /* sdjhgsfdsygd */
    {
      // foo
      "extends": "astro/tsconfigs/strict",
      /* bar */
      "include": [".astro/types.d.ts", "**/*"], /* baz */
      "exclude": ["dist"]
    }
   ```

   Feel free to make the file as pathologically weird as you can in the limits of JSONC, add more `extends`, etc.

3. Open a buffer in that directory and play around:

   ```
   $ vim
   ```
   ```
   :echo jsonc#ParseJSONCRecursively('tsconfig.json')
   ```
