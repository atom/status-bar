import { createPlugins } from "rollup-plugin-atomic";

const plugins = createPlugins(["js", "coffee", "babel"]);

export default [
  {
    input: "lib/main.js",
    output: [
      {
        dir: "dist",
        format: "cjs",
        sourcemap: true,
      },
    ],
    // loaded externally
    external: [
      "atom",
    ],
    plugins: plugins,
  },
];
