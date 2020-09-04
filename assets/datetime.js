import flatpickr from "flatpickr";
import flatpickr_css from "../../node_modules/flatpickr/dist/flatpickr.min.css";

var datetimeElements = document.querySelectorAll(".boldtip-field-datetime input");

Array.prototype.forEach.call(datetimeElements, function (datetimeElement) {
    flatpickr(datetimeElement, {
        enableTime: true,
        dateFormat: "Z"
    });
});