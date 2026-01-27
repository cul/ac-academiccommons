// Global Type Declarations go here

import type Jquery from 'jquery';

declare global {
  interface Window {
    $: typeof Jquery;
    jQuery: typeof Jquery;
  }
}

export {}; // tells tsc this is a module file and therefore the above declaration is actually global