// ==UserScript==
// @name         YtSkip
// @namespace    http://englard.net/
// @version      0.1
// @description  Skip YouTube redirect permission page.
// @author       Shmuelie
// @match        https://www.youtube.com/redirect*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    window.location = document.getElementById("invalid-token-redirect-goto-site-button").href;
})();