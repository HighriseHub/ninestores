// nine-spinner.js

(function(global) {
  function NineStoresSpinner(container) {
    this.container = typeof container === 'string'
      ? document.querySelector(container)
      : container || document.body;

    this.spinnerHTML = `
      <div id="custom-spinner-wrapper" style="
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        z-index: 9999;
      ">
        <svg width="80" height="80" viewBox="0 0 100 100" style="animation: spin 2s linear infinite;">
          <circle cx="50" cy="50" r="40" stroke="#4D148C" stroke-width="8" fill="none" stroke-linecap="round" />
          <text x="50%" y="50%" text-anchor="middle" fill="#FF6600" dy=".3em" font-size="12" font-weight="bold">
            Nine Stores
          </text>
        </svg>
      </div>
    `;

    this.injectStyles();
  }

  NineStoresSpinner.prototype.injectStyles = function() {
    if (!document.getElementById('nine-spinner-style')) {
      const style = document.createElement('style');
      style.id = 'nine-spinner-style';
      style.textContent = `
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `;
      document.head.appendChild(style);
    }
  };

  NineStoresSpinner.prototype.show = function() {
    if (!document.getElementById('custom-spinner-wrapper')) {
      const wrapper = document.createElement('div');
      wrapper.innerHTML = this.spinnerHTML;
      this.container.appendChild(wrapper.firstElementChild);
    }
  };

  NineStoresSpinner.prototype.hide = function() {
    const el = document.getElementById('custom-spinner-wrapper');
    if (el) el.remove();
  };

  // Expose to global scope
  global.NineStoresSpinner = NineStoresSpinner;

})(window);
