declare const SRC: string

declare module "inline:*" {
  const content: string
  export default content
}

declare module "*.scss" {
  const content: string
  export default content
}

declare module "*.blp" {
  const content: string
  export default content
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      // registered at runtime in app.ts (ags does not ship it)
      progressbar: import("gi://Gtk?version=4.0").ProgressBar
    }
  }
}

declare module "*.css" {
  const content: string
  export default content
}
