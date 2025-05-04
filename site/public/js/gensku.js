document.addEventListener('DOMContentLoaded', function() {
  const skuGenerator = {
    init: function() {
      this.cacheElements();
      this.bindEvents();
      this.generateSku(); // Generate initial SKU
    },
    
    cacheElements: function() {
      this.elements = {
	  productName: document.getElementById('idproductName'),
          productDescription: document.getElementById('idproductDescription'),
          quantityValue: document.getElementById('idqtyperunit'),
          unitOfMeasure: document.getElementById('idunitOfMeasure'),
          generatedSku: document.getElementById('idgeneratedSku'),
          generateSkuBtn: document.getElementById('generateSkuBtn'),
          copySkuBtn: document.getElementById('copySkuBtn'),

      };
    },
    
    bindEvents: function() {
      // Button click events
      this.elements.generateSkuBtn.addEventListener('click', () => this.generateSku());
      this.elements.copySkuBtn.addEventListener('click', () => this.copySkuToClipboard());
      
      // Field change events (using proper event types)
      this.elements.productName.addEventListener('input', () => this.generateSku());
      this.elements.productDescription.addEventListener('input', () => this.generateSku());
      this.elements.quantityValue.addEventListener('input', () => this.generateSku());
      
      // Fixed UOM dropdown event - using 'change' event properly
      this.elements.unitOfMeasure.addEventListener('change', () => {
        this.generateSku();
      });
    },
    
    generateSku: function() {
      // Basic validation
      if (!this.elements.productName.value.trim()) {
        this.elements.generatedSku.value = 'Please enter a product name';
        return;
      }
      
      // Get values
      const name = this.elements.productName.value.trim();
      const desc = this.elements.productDescription.value.trim();
      const qty = parseFloat(this.elements.quantityValue.value) || 1; // Default to 1 if invalid
      const uom = this.elements.unitOfMeasure.value;
      
      // Process name - take first 3 letters of each word
      const nameParts = name.split(/\s+/);
      let nameCode = '';
      for (let i = 0; i < Math.min(nameParts.length, 3); i++) {
        if (nameParts[i].length > 0) {
          nameCode += nameParts[i].substring(0, 2).toUpperCase();
        }
      }
      
      // Process description - take first letter of each word
      let descCode = '';
      if (desc) {
        const descParts = desc.split(/\s+/);
        for (let i = 0; i < Math.min(descParts.length, 3); i++) {
          if (descParts[i].length > 0) {
            descCode += descParts[i].substring(0, 1).toUpperCase();
          }
        }
      }
      
      // Generate random 4-digit number
      const randomNum = Math.floor(1000 + Math.random() * 9000);
      
      // Combine all parts with dashes
      let sku = nameCode;
      if (descCode) sku += `-${descCode}`;
      sku += `-${qty}${uom}-${randomNum}`;
      
      this.elements.generatedSku.value = sku;
    },
    
    copySkuToClipboard: function() {
      if (!this.elements.generatedSku.value || 
          this.elements.generatedSku.value.startsWith('Please')) {
        return;
      }
      
      // Copy to clipboard
      this.elements.generatedSku.select();
      this.elements.generatedSku.setSelectionRange(0, 99999);
      document.execCommand('copy');
      
      // Show feedback
      const originalText = this.elements.copySkuBtn.innerHTML;
      this.elements.copySkuBtn.innerHTML = '<i class="bi bi-check"></i> Copied!';
      setTimeout(() => {
        this.elements.copySkuBtn.innerHTML = originalText;
      }, 2000);
    }
  };
  
  skuGenerator.init();
});

