var $busyindicator = document.getElementById('busy-indicator');
const ninespinner = new NineStoresSpinner ($busyindicator);

var $error = document.getElementById('hhub-error');
var $success = document.getElementById('hhub-success');
var  $formcustsignin = $(".form-custsignin"),  $formvendsignin = $(".form-vendorsignin");
var cartitemscount = 0;
// Create a generic JQuery AJAX function
var ajaxCallParams = {};
var ajaxDataParams = {}; 
var slideindex =1;

// disable right click for the entire site. 
document.addEventListener('contextmenu', event => event.preventDefault());


async function checkExistingAddress(phone) {
  if (phone.length === 10) {
    try {
      const res = await fetch(`/hhub/nstcustomeraddress/${phone}`);
      const data = await res.json();
      if (data && data.addresses && data.addresses.length > 0) {
        const container = document.getElementById('saved-addresses-section');
        const tiles = document.getElementById('saved-address-tiles');
        container.style.display = 'block';
        tiles.innerHTML = '';
        data.addresses.forEach(addr => {
          const card = document.createElement('div');
          card.className = 'card border-primary';
          card.style.width = '15rem';
          card.innerHTML = `
            <div class="card-body">
              <p class="card-text">${addr.custname}<br>${addr.address}<br>${addr.city}, ${addr.state}, ${addr.zipcode}</p>
              <button type="button" class="btn btn-outline-primary btn-sm" onclick='useSavedAddress(${JSON.stringify(addr)}, event);'>Use this address</button>
            </div>`;
          tiles.appendChild(card);
        });
      }
    } catch (err) {
      console.error('Error fetching addresses:', err);
    }
  }
}

function useSavedAddress(addr) {
    event.stopPropagation();
    event.preventDefault();
    document.getElementById('shipaddress').value = addr.address;
    document.getElementById('shipcity').value = addr.city;
    document.getElementById('shipstate').value = addr.state;
    document.getElementById('shipzipcode').value = addr.zipcode;
    document.getElementById('custname').value = addr.custname;
    document.getElementById('email').value = addr.email;
}


// Final recommended implementation (universal)
function generateUniqueId() {
    if (typeof crypto !== 'undefined' && crypto.randomUUID) {
        return crypto.randomUUID();
    }
    // Fallback for older environments
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
}


const validateFileSize = (event) => {
    event.preventDefault();
    const input = event.target;
    const files = input.files;
    const maxFiles = 5;
    const maxSizeMB = 1; // Maximum file size in MB
    const maxSizeBytes = maxSizeMB * 1024 * 1024; // Convert MB to bytes

    // Check if no files are selected
    if (files.length === 0) {
        alert("Please select at least one file.");
        return false;
    }

    // Check if more than 5 files are selected
    if (files.length > maxFiles) {
        alert(`You can upload a maximum of ${maxFiles} files at a time.`);
        document.getElementById("btnprdimageupload").disabled = true;
        return false;
    }

    // Validate file size and type
    for (let i = 0; i < files.length; i++) {
        const file = files[i];

        // Check file size
        if (file.size > maxSizeBytes) {
            alert(`File "${file.name}" exceeds the maximum size of ${maxSizeMB} MB. Please select a smaller file.`);
            document.getElementById("btnprdimageupload").disabled = true;
            return false;
        }

        // Check file type (only images allowed)
        if (!file.type.match('image.*')) {
            alert(`File "${file.name}" is not an image. Please upload only image files.`);
            document.getElementById("btnprdimageupload").disabled = true;
            return false;
        }

        // Display image preview
        const previewElement = document.getElementById(`img_url_${i + 1}`);
        if (previewElement) {
            previewElement.src = URL.createObjectURL(file);
	    previewElement.style = "width:100px; height:100px; display:block;";
        }
    }

    // Add onClick event for the reset button
    var element = document.getElementById("btnprdimageuploadreset");
    element.addEventListener('click', resetFileUpload);

    // Enable the upload button if all validations pass
    document.getElementById("btnprdimageupload").disabled = false;
    return true;
};

const resetFileUpload = () => {
    // Reset the file input
    const input = document.getElementById("idprdimgfileupldctrl");
    const files = input.files;
    if (input && files.length > 0) {
        input.value = ''; // This clears the selected files
	// Clear image previews (if any)
	for (let i = 1; i <= files.length; i++) { // Assuming you have 5 image preview slots
            const previewElement = document.getElementById(`img_url_${i}`);
            if (previewElement) {
		previewElement.src = ''; // Clear the image source
		previewElement.style.display = 'none'; // Hide the preview element
            }
	}
	
    // Optionally, disable the upload button
	const uploadButton = document.getElementById("btnprdimageupload");
	if (uploadButton) {
            uploadButton.disabled = true;
	}
    }
};

/**
 * Uploads a file to a backend URL with progress tracking.
 * @param {string} backendUrl - The URL to which the file will be uploaded.
 * @param {File} file - The file to upload.
 * @param {function} onProgress - Callback function to track upload progress.
 * @returns {Promise} - Resolves with the server response or rejects with an error.
 */
const uploadFileToBackend = (form, onProgress) => {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
	const formData = new FormData(form);
	const backendUrl = form.action; 
	const input = document.getElementById("idprdimgfileupldctrl");
	const files = input.files;

	    // Check if no files are selected
	if (files.length === 0) {
            alert("Please select at least one file.");
            return false;
	}

        // Set up the request
        xhr.open("POST", backendUrl, true);

        // Track upload progress
        xhr.upload.onprogress = (event) => {
            if (event.lengthComputable) {
                const percentCompleted = Math.round((event.loaded * 100) / event.total);
                if (onProgress) {
                    onProgress(percentCompleted); // Call the progress callback
                }
            }
        };

        // Handle the response
        xhr.onload = () => {
            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const response = xhr.responseText;
                    resolve(response); // Resolve with the server response
                } catch (error) {
                    reject(new Error("Failed to parse server response."));
                }
            } else {
                reject(new Error(`Upload failed: ${xhr.statusText}`));
            }
        };

        // Handle errors
        xhr.onerror = () => {
            reject(new Error("Network error during upload."));
        };

	// set the header for uniquie id for tracking
	xhr.setRequestHeader('X-Request-ID', generateUniqueId()); // For tracking
        // Send the request
        xhr.send(formData);
    });
};


const submitfileuploadevent = async (event) => {
    const theForm = event.target;
    const fileInput = document.getElementById("idprdimgfileupldctrl");
    event.preventDefault();
    try {
        // Optional: Track upload progress
	const onProgress = (percentCompleted) => {
            document.getElementById("fileuploadprogress").textContent = `Uploading: ${percentCompleted}%`;
        };

        // Upload the file
        const response = await uploadFileToBackend(theForm, onProgress);
        console.log("Upload successful:", response);
        location.replace(response);

    } catch (error) {
        console.error("Upload failed:", error);
        alert("File upload failed. Please try again.");
    }
};



const setRangeValue = (event)=>{
    
    const range = event.target;
    const id = event.target.id; 
    const prdrowid = id.substring(id.indexOf("_") + 1);
    const rangeV = document.querySelector('#rangeV_' + prdrowid);
    const
    newValue = Number( (range.value - range.min) * 100 / (range.max - range.min) ),
    newPosition = 10 - (newValue * 0.2);
    rangeV.innerHTML = `<span>${range.value}</span>`;
    rangeV.style.left = `calc(${newValue}% + (${newPosition}px))`;
    };

const oninput = (event)=>{
    
    const range = event.target;
    const id = event.target.id; 
    const prdrowid = id.substring(id.indexOf("_") + 1);
    const rangeV = document.querySelector('#rangeV_' + prdrowid);
    const
    newValue = Number( (range.value - range.min) * 100 / (range.max - range.min) ),
    newPosition = 10 - (newValue * 0.2);
    rangeV.innerHTML = `<span>${range.value}</span>`;
    rangeV.style.left = `calc(${newValue}% + (${newPosition}px))`;
    };



$(document).ready(function() {
  var $navbar = $("#hhubcustnavbar");
  
  StickyHeader(); // Incase the user loads the page from halfway down (or something);
  $(window).scroll(function() {
      StickyHeader();
  });
    
    function StickyHeader(){
	if ($(window).scrollTop() > 60) {
	    if (!$navbar.hasClass("navbar-fixed-top")) {
		$navbar.addClass("navbar-fixed-top");
	    }
	} else {
	    $navbar.removeClass("navbar-fixed-top");
	}
    }
});


$(document).ready(function(){
    cartitemscount = 0;
    var carouselcontainer = document.getElementById('carousel-container');
    if(carouselcontainer != null){
	//setInterval(performslideshow, 6000);
    }
});

function performslideshow(){
    var linkid, previouslinkid, link, previouslink;; 
    if(slideindex == 6)
    {
	previouslinkid = "#slidelink" + (slideindex -1);
	previouslink = document.querySelector(previouslinkid);
	previouslink.style = "background-color: white;"
	slideindex =1;
    }
    else
    {
	linkid = "#slidelink" + slideindex;
	link = document.querySelector(linkid);
	link.style = "background-color: grey;"
	
	    // We will click the button only if we are in the first 300 pixels
	if ($(window).scrollTop() < 300) {
	    link.click();
	}
	
	if(slideindex > 1){
	    previouslinkid = "#slidelink" + (slideindex -1);
	    previouslink = document.querySelector(previouslinkid);
	    previouslink.style = "background-color: white;"
	}
	slideindex++;
    }
    
}



function countdowntimer (days, hours, minutes, seconds){ 
    // Set the date we're counting down to
    var countDownDate =  new Date().getTime(); 
    if (days > 0 ){
	countDownDate = countDownDate + 1000 * 60 * 60 * 24 * days;
    } 
    if (hours > 0) {
	countDownDate = countDownDate + 1000 * 60 * 60 * hours;
    }
    if (minutes > 0) {
	countDownDate += 1000 * 60 *  minutes; 
    }
    if (seconds > 0) {
	countDownDate += 1000 *  seconds ; 
    }
    // Update the count down every 1 second
    var x = setInterval(function() {
	// Get today's date and time
	var now = new Date().getTime();
	
	// Find the distance between now and the count down date
	var distance = countDownDate - now;
	
	// Time calculations for days, hours, minutes and seconds
	var days = Math.floor(distance / (1000 * 60 * 60 * 24));
	var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
	var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
	var seconds = Math.floor((distance % (1000 * 60)) / 1000);
	
	// Output the result in an element with id="demo"
	if (days > 0 && hours >0){ 
	document.getElementById("withCountDownTimer").innerHTML = days + "d " + hours + "h "
		+ minutes + "m " + seconds + "s ";
	}
	else{
	    document.getElementById("withCountDownTimer").innerHTML =  minutes + "m " + seconds + "s ";
	}
	
	// If the count down is over, write some text 
	if (distance < 0) {
	    clearInterval(x);
	    document.getElementById("withCountDownTimerExpired").innerHTML = "SESSION EXPIRED";
	}
    }, 1000);
}

// General function for all ajax calls
function ajaxCall(callParams, dataParams, callback) {   
    $.ajax({
        type: callParams.Type,
        url: callParams.Url,
	quietMillis: 100,
        dataType: callParams.DataType,
        data: dataParams,
        cache: true,
	beforeSend: function(){
	    ninespinner.show();
	},
	complete: function(){
	    ninespinner.hide();
	},
	success:function (response) {
            callback(response);
        },
        error: function (jqXHR, textStatus, errorThrown) {
            if (jqXHR.status > 400){
		displayError("#hhub-error", jqXHR.responseText);
		console.log("HTTP Error Code" + jqXHR.status);
		console.log("Error Status: "+ textStatus);
		console.log("Error Thrown: "+ errorThrown);
	    }}
    });
}

function goback (){
    window.onpageshow = function(event) {
	if (event.persisted) {
	    window.location.reload()
	}
    };
}

function pincodecheck (addressfield, pincodefield, cityfield, statefield, areafield){
    var city = cityfield;
    var pincode = pincodefield.val();
    var state = statefield;
    var localarea = areafield;
    var address = addressfield;
    var addressval = address.val();
    
    if (pincode.length  == 6){
	ajaxCallParams.Type = "GET"; 
	ajaxCallParams.Url = "/hhub/hhubpincodecheck";
	ajaxCallParams.DataType = "JSON"; // Return data type e-g Html, Json etc
	
	// Set Data parameters
	ajaxDataParams.pincode = pincode; 
        
	// Passing call and data parameters to general Ajax function
	ajaxCall(ajaxCallParams, ajaxDataParams, function (retdata) {
	   
	    if(retdata['success'] != 0){
		console.log(retdata);
		var data = retdata['result'];
		city.val(data[0].locality + ", " +  data[0].city)
		state.val(data[0].state);
		localarea.text(data[0].locality);
		
	    }
	    else
	    {
		city.val("");
		state.val("");
		localarea.text("");
	    }
		
	});
    }

}

$(document).ready(function() {
    $('#shipzipcode').keyup(function(){
        pincodecheck($('#shipaddress'),$('#shipzipcode'),$('#shipcity'), $('#shipstate'), $('#areaname'));
    });
});


$(document).ready(function() {
    $('#cmpzipcode').keyup(function(){
        pincodecheck($('#cmpaddress'),$('#cmpzipcode'), $('#cmpcity'), $('#cmpstate'), $('#areaname'));
    });
});



/*$pricingform.submit(function(e){
    var theForm = $(this);
    $(theForm).find("button[type='submit']").hide();
    ajaxCallParams.Type = "POST"; // POST type function 
    ajaxCallParams.Url = $(theForm).attr("action"); // Pass Complete end point Url e-g Payment Controller, Create Action
    ajaxCallParams.DataType = "HTML"; // Return data type e-g Html, Json etc
    
    // Set Data parameters
    ajaxDataParams = $(theForm).serialize();
    
    // Passing call and data parameters to general Ajax function
    ajaxCall(ajaxCallParams, ajaxDataParams, function (result) {
	window.location.replace("/hhub/hhubnewcompreqemailsent");
	displaySuccess("#hhub-success",result);
    });
    e.preventDefault();
});
*/


function displaybillingaddress() {
    const checkbox = document.getElementById('billsameasshipchecked');
    if (checkbox.checked) {
        // Always sync billing with shipping
        copyshiptobillto();
        // Hide billing UI (UX only)
        $('#billingaddressrow').hide();
    } else {
        // User wants to enter billing manually
        $('#billingaddressrow').show();
    }
}


function displaygstdetails () {
    if( document.getElementById('claimitcchecked').checked ){
	$('#gstdetailsfororder').show();
    }else
    {
	$('#gstdetailsfororder').hide();
    }

}

function togglecheckboxvalueyn(id){
    const checkboxtoggle  = document.getElementById(id);
    if(checkboxtoggle.checked ){
         checkboxtoggle.value = "Y";
    }else
    {
         checkboxtoggle.value = "N";
    }
}

function clearbilltoaddress(){
    var billaddress = document.getElementById("billaddress");
    var billzipcode = document.getElementById("billzipcode");
    var billcity = document.getElementById("billcity");
    var billstate = document.getElementById("billstate");
    billaddress.value = "";
    billzipcode.value = "";
    billcity.value = "";
    billstate.value = ""; 
}


function copyshiptobillto()
{
    var shipaddress  = document.getElementById("shipaddress");
    var billaddress = document.getElementById("billaddress");
    var shipzipcode = document.getElementById("shipzipcode");
    var billzipcode = document.getElementById("billzipcode");
    var shipcity = document.getElementById("shipcity");
    var billcity = document.getElementById("billcity");
    var shipstate = document.getElementById("shipstate");
    var billstate = document.getElementById("billstate");
    
    billaddress.value = shipaddress.value;
    billzipcode.value = shipzipcode.value;
    billcity.value = shipcity.value;
    billstate.value = shipstate.value;
    
}


$( ":text" ).each(function( index ) {
    $( this ).focusout(function() {
      var text = $(this).val();
      text = $.trim(text);
      $(this).val(text);
    });
});



function fallbackCopyTextToClipboard(text) {
  var textArea = document.createElement("textarea");
  textArea.value = text;
  
  // Avoid scrolling to bottom
    textArea.style.top = "0";
    textArea.style.left = "0";
    textArea.style.position = "fixed";

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    var successful = document.execCommand('copy');
    var msg = successful ? 'successful' : 'unsuccessful';
    console.log('Fallback: Copying text command was ' + msg);
  } catch (err) {
    console.error('Fallback: Oops, unable to copy', err);
  }

    document.body.removeChild(textArea);
    displaySuccess("#hhub-success","Copied To Clipboard");   
}


const copyToClipboard = text => {
  if (!navigator.clipboard) {
    fallbackCopyTextToClipboard(text);
    return;
  }
  navigator.clipboard.writeText(text).then(function() {
    console.log('Async: Copying to clipboard was successful!');
  }, function(err) {
    console.error('Async: Could not copy text: ', err);
  });
    displaySuccess("#hhub-success","Copied To Clipboard");   
}


function getCookie(k)
{
    var v=document.cookie.match('(^|;) ?'+k+'=([^;]*)(;|$)');
    return v?v[2]:null
}



$(document).ready(function(){
    //$busyindicator.removeChild(spinner.el);
});


$(document).ready(function() {
        $('[data-toggle="tooltip"]').tooltip({'placement': 'top'});
});


function addtocartclick (id){
    event.preventDefault();

    const addtocartbtn = document.querySelector("#"+id);
    const prdrowid = id.substring(id.indexOf("_") + 1);

    const range = document.querySelector('#range_' + prdrowid);
    const rangeV = document.querySelector('#rangeV_' + prdrowid);
    range.addEventListener('input', setRangeValue);

    const
    newValue = Number( (range.value - range.min) * 100 / (range.max - range.min) ),
    newPosition = 10 - (newValue * 0.2);
    rangeV.innerHTML = `<span>${range.value}</span>`;
    rangeV.style.left = `calc(${newValue}% + (${newPosition}px))`;

}


function orderitemeditclick (id){                                                                                                                                              
    event.preventDefault();
    const editorderitembtn = document.querySelector("#"+id);
    const prdrowid = id.substring(id.indexOf("_") + 1);
    const range = document.querySelector('#range_' + prdrowid);
    const rangeV = document.querySelector('#rangeV_' + prdrowid);
    range.addEventListener('input', setRangeValue);
    const
    newValue = Number( (range.value - range.min) * 100 / (range.max - range.min) ),
    newPosition = 10 - (newValue * 0.2);
    rangeV.innerHTML = `<span>${range.value}</span>`;
    rangeV.style.left = `calc(${newValue}% + (${newPosition}px))`;
}


function plusbtnclick (id){
    event.preventDefault();
    const plusbutton = document.querySelector("#"+id);
    const  prdrowid = id.substring(id.indexOf("_") + 1);
    const  elemname = "#prdqtyfor_" + prdrowid; 
    const  prdqtyelem = document.querySelector(elemname);
    prdqtyelem.valueAsNumber++;
}

function minusbtnclick (id){
    event.preventDefault();
    const plusbutton = document.querySelector("#"+id);
    const prdrowid = id.substring(id.indexOf("_") + 1);
    const elemname = "#prdqtyfor_" + prdrowid; 
    const prdqtyelem = document.querySelector(elemname);
    if(prdqtyelem.value == 0) return false; 
    prdqtyelem.valueAsNumber--;
}




function countChar (divid, val, maxchars ) {
    event.preventDefault();
    var charcountdiv = document.getElementById(divid);
    var length = val.value.length; 
    if (length >= maxchars+1){
	val.value = val.value.substring(0, maxchars);
	charcountdiv.textContent = "Length Exceeded beyond - " + maxchars; 
    }else {
	charcountdiv.textContent = maxchars - length;
    }
}



$formcustsignin.submit ( function() {
    $formcustsignin.hide();
    $.ajax({
	type: "POST",
	url: $formcustsignin.attr("action"),
	data: $formscustignin.serialize(),
	error:function(){
	$error.show();
	},
   	success: function(response){
	    console.log("Customer Signin successful");
	    window.location = "/dodcustindex"; 
	    location.reload(); 

	}
    })
    return false;
    
})

$(document).ready(
    function() {
        $( "#required-on" ).datepicker({dateFormat: "dd/mm/yy", minDate: 1} ).attr("readonly", "true");
    }
);



$formvendsignin.submit ( function() {
    $formvendsignin.hide();
    $.ajax({
	type: "POST",
	url: $formsignin.attr("action"),
	data: $formvendsignin.serialize(),
	error:function(){
	$error.show();
	},
   	success: function(response){
	    console.log("Vendor Signin successful");
	    window.location = "/dodvendindex";  
	    location.reload(); 

	}
    })
    return false;
    
})

function displayError(elem, message, timeout) {
    $(elem).show().html('<div class="alert alert-warning alert-dismissible"> <button type="button" class="close" data-bs-dismiss="alert" aria-label="Close" style="outline: none;"><span aria-hidden="true">&times;</span></button><strong>Warning!&nbsp;</strong>' + message + '</div>');
    if (timeout || timeout === 0) {
    setTimeout(function() { 
      $(elem).alert('close');
    }, timeout);    
  }
};

function displaySuccess(elem, message, timeout) {
    $(elem).show().html('<div class="alert alert-success alert-dismissible"> <button type="button" class="close" data-bs-dismiss="alert" aria-label="Close" style="outline: none;"><span aria-hidden="true">&times;</span></button><strong>Success!&nbsp;</strong>' + message + '</div>');
    if (timeout || timeout === 0) {
    setTimeout(function() { 
	$(elem).alert('close');
	$(elem).hide();
	
    }, timeout);    
  }
};


$(".form-vendordercomplete").on('submit', function (e) {
    var theForm = $(this);
    $(theForm).find("button[type='submit']").hide(); //prop('disabled',true);
      $.ajax({
            type: 'POST',
          url: $(theForm).attr("action"), 
            data: $(theForm).serialize(),
	  error: function (jqXHR, textStatus, errorThrown) {
                  if (jqXHR.status == 500) {
		      displayError("#hhub-error", jqXHR.responseText);
		  }
	      else{
                      alert('Unexpected error.');
                  }},
	  success: function (response) {
		console.log("Completing the Order "); 
		location.reload();
            }
      });
      e.preventDefault();});

//We are using event delegation here. #searchresult is 

/*$(document).ready(function() {
    registerforsubmitformevent ("#hhubmaincontent");
});*/


$(document).ready(function() {
    registerforsubmitformevent ("#prdlivesearchresult");
});


$(document).ready(function() {
    registerforsubmitformevent ("#idsingle-product-card");
});


$(document).ready(function() {
    registerforsubmitformevent ("#idprd-catg-container");
});

$(document).ready(function() {
    registerforsubmitformevent ("#idstdcustcodcontainer");
});


function submitonkeyupevent (event){
    event.preventDefault();
    let tergetform = event.target;
    searchformsubmit(targetform, resultelem); 
}

const registeronkeyupevent = (component, resultelem) => {
    const element = document.querySelector(component);
    if (null != element){
	element.addEventListener('keyup', (e) => {
	    e.preventDefault();
	    let targetform = e.target;
	    searchformsubmit(targetform, resultelem);
	});
    }
};


const registerforsubmitformevent = (component) => {
    const element = document.querySelector(component);
    if (null != element){
	element.addEventListener('submit', (e) => {
	    e.preventDefault();
	    let targetform = e.target;
	    submitformandredirect(targetform);
	});
    }
};


function submitformandredirect (theForm){
    $(theForm).find("button[type='submit']").hide();
    ajaxCallParams.Type = "POST";
    ajaxCallParams.Url = $(theForm).attr("action");
    ajaxCallParams.DataType = "HTML"; // Return data type e-g Html, Json etc                                                                                                                                    
    ajaxDataParams  = $(theForm).serialize();
    //  ajaxDataParams  = new FormData(theForm);
    ajaxCall(ajaxCallParams, ajaxDataParams, function (data) { 
	console.log("Form submitted");
	if (data.includes("pdf"))
	    window.open(data); 
	else
	    location.replace(data);
	
    });
}

function searchformsubmit (theForm, resultdiv){
    $(theForm).find("button[type='submit']").hide();
    ajaxCallParams.Type = "POST";
    ajaxCallParams.Cache = false;
    ajaxCallParams.Url = $(theForm).attr("action");
    ajaxCallParams.DataType = "HTML"; // Return data type e-g Html, Json etc                                                                                                                                    
    ajaxDataParams = $(theForm).serialize();
    ajaxCall(ajaxCallParams, ajaxDataParams, function (data) { 
	console.log("Search Form submitted");
	$(resultdiv).html(data);
    });
}



$(".form-shopcart").on('submit', function (e){
    e.preventDefault();
    var theForm = $(this);
    submitformandredirect (theForm);
});

	

function goBack (){
    window.history.back();
}



function CancelConfirm (){
    return confirm("Do you really want to Cancel?");
}

function DeleteConfirm (){
    return confirm("Do you really want to Delete?");
}




$(document).ready (function(){
    var btn = $('#scrollup');
    
    $(window).scroll(function() {
	if ($(window).scrollTop() > 300) {
	    btn.addClass('show');
	} else {
	    btn.removeClass('show');
	}
    });
    
    btn.on('click', function(e) {
	e.preventDefault();
	$('html, body').animate({scrollTop:0}, '300');
    });
}); 


$(document).ready (function(){
    var floatingbtn = $('#floatingcheckoutbutton');
    
    $(window).scroll(function() {
	if ($(window).scrollTop() > 300) {
	    floatingbtn.addClass('show');
	} else {
	    floatingbtn.removeClass('show');
	}
    });
    
    floatingbtn.on('click', function(e) {
	//e.preventDefault();
	//$('html, body').animate({scrollTop:0}, '300');
    });
}); 


function searchformevent(idBindElement, searchresultid) {
    var theForm = event.target.form;
    var element = document.querySelector(idBindElement);
    return element.value.length === 3 ||
	element.value.length === 5 ||
	element.value.length === 8 ||
	element.value.length === 13 ||
	element.value.length === 21 ? searchformsubmit(theForm, searchresultid) : null;
}

