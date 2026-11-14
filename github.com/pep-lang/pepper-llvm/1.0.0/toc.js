// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded affix "><a href="index.html">llvm</a></li><li class="chapter-item expanded "><a href="module.html"><strong aria-hidden="true">1.</strong> llvm</a></li><li class="chapter-item expanded "><a href="builder.html"><strong aria-hidden="true">2.</strong> builder.pep</a></li><li class="chapter-item expanded "><a href="context.html"><strong aria-hidden="true">3.</strong> context.pep</a></li><li class="chapter-item expanded "><a href="debug_info.html"><strong aria-hidden="true">4.</strong> debug_info.pep</a></li><li class="chapter-item expanded "><a href="enums.html"><strong aria-hidden="true">5.</strong> enums.pep</a></li><li class="chapter-item expanded "><a href="ir_module.html"><strong aria-hidden="true">6.</strong> ir_module.pep</a></li><li class="chapter-item expanded "><a href="jit.html"><strong aria-hidden="true">7.</strong> jit.pep</a></li><li class="chapter-item expanded "><a href="llvm_c-module.html"><strong aria-hidden="true">8.</strong> llvm.llvm_c</a></li><li class="chapter-item expanded "><a href="llvm_c-core.html"><strong aria-hidden="true">9.</strong> llvm_c/core.pep</a></li><li class="chapter-item expanded "><a href="llvm_c-debug_info.html"><strong aria-hidden="true">10.</strong> llvm_c/debug_info.pep</a></li><li class="chapter-item expanded "><a href="llvm_c-link.html"><strong aria-hidden="true">11.</strong> llvm_c/link.pep</a></li><li class="chapter-item expanded "><a href="llvm_c-orc.html"><strong aria-hidden="true">12.</strong> llvm_c/orc.pep</a></li><li class="chapter-item expanded "><a href="llvm_c-target.html"><strong aria-hidden="true">13.</strong> llvm_c/target.pep</a></li><li class="chapter-item expanded "><a href="target.html"><strong aria-hidden="true">14.</strong> target.pep</a></li><li class="chapter-item expanded "><a href="values.html"><strong aria-hidden="true">15.</strong> values.pep</a></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split("#")[0].split("?")[0];
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);
