nabu.services.VueService(Vue.extend({
	methods: {
		format: function(value, properties, page, cell) {
			if (!properties.format) {
				return value;
			}
			else if (properties.format == "checkbox") {
				return "<n-form-checkbox :value='value' />";
			}
			else if (value == null || typeof(value) == "undefined") {
				return null;
			}
			// formatting is optional
			else if (!properties.format || properties.format == "text") {
				return value;
			}
			else if (properties.format == "html") {
				return properties.html ? properties.html : value;
			}
			else if (properties.format == "link") {
				return "<a target='_blank' ref='noopener noreferrer nofollow' href='" + value + "'>" + value.replace(/http[s]*:\/\/([^/]+).*/, "$1") + "</a>";
			}
			else if (properties.format == "date") {
				if (value && properties.isTimestamp) {
					value = new Date(value);
				}
				else if (value && properties.isSecondsTimestamp) {
					value = new Date(1000 * value);
				}
				return this.date(value, properties.dateFormat);
			}
			// backwards compatibility
			else if (properties.format == "dateTime") {
				return this.date(value, "dateTime");
			}
			else if (properties.format == "number") {
				return this.number(value, properties.amountOfDecimals);
			}
			else if (properties.format == "masterdata") {
				return this.masterdata(value);
			}
			else if (properties.format == "javascript") {
				return this.javascript(value, properties.javascript);
			}
			// otherwise we are using a provider
			else {
				var result = nabu.page.providers("page-format").filter(function(x) { return x.name == properties.format })[0]
					.format(value, properties, page, cell);
				return result;
			}
		},
		javascript: function(value, code) {
			if (code instanceof Function) {
				return code(value);
			}
			else {
				var result = eval(code);
				if (result instanceof Function) {
					result = result(value);
				}
				return result;
			}
		},
		date: function (date) {
			if ( !(date instanceof Date) ) {
				return date;
			}
			return [this.leftpad(date.getDate()), this.leftpad(date.getMonth() + 1), date.getFullYear()].join("/");
		},
		date: function(date, format) {
			if (!date) {
				return null;
			}
			else if (typeof(date) == "string") {
				date = new Date(date);
			}
			if (!format || format == "date") {
				format = "yyyy-MM-dd";
			}
			else if (format == "dateTime") {
				format = "yyyy-MM-ddTHH:mm:ss.SSS";
			}
			format = format.replace(/yyyy/g, date.getFullYear());
			format = format.replace(/yy/g, ("" + date.getFullYear()).substring(2, 4));
			format = format.replace(/dd/g, (date.getDate() < 10 ? "0" : "") + date.getDate());
			format = format.replace(/d/g, date.getDate());
			format = format.replace(/HH/g, (date.getHours() < 10 ? "0" : "") + date.getHours());
			format = format.replace(/H/g, date.getHours());
			format = format.replace(/mm/g, (date.getMinutes() < 10 ? "0" : "") + date.getMinutes());
			format = format.replace(/m/g, date.getMinutes());
			format = format.replace(/ss/g, (date.getSeconds() < 10 ? "0" : "") + date.getSeconds());
			format = format.replace(/s/g, date.getSeconds());
			format = format.replace(/[S]+/g, date.getMilliseconds());
			// we get an offset in minutes
			format = format.replace(/[X]+/g, Math.floor(date.getTimezoneOffset() / 60) + ":" + date.getTimezoneOffset() % 60);
			// do months last as they can introduce named months which might conflict with expressions in the above
			// e.g. "Sep" could trigger the millisecond replacement
			// replacing a month with "May" could trigger the single "M" replacement though
			// so first we replace the capital M with something that should never conflict
			format = format.replace(/M/g, "=");
			format = format.replace(/====/g, nabu.utils.dates.months()[date.getMonth()]);
			format = format.replace(/===/g, nabu.utils.dates.months()[date.getMonth()].substring(0, 3));
			format = format.replace(/==/g, (date.getMonth() < 9 ? "0" : "") + (date.getMonth() + 1));
			format = format.replace(/=/g, date.getMonth() + 1);
			return format;
		},
		humanDate: function (date) {
			if (!date) {
				date = new Date();
			}
			var months = [
				"%{date:januari}",
				"%{date:februari}",
				"%{date:maart}",
				"%{date:april}",
				"%{date:mei}",
				"%{date:juni}",
				"%{date:juli}",
				"%{date:augustus}",
				"%{date:september}",
				"%{date:oktober}",
				"%{date:november}",
				"%{date:december}"
			]
			return date.getDate() + " " + months[date.getMonth()] + " " + date.getFullYear();
		},
		dateTime: function (date) {
			var datePart = this.date(date);
			var time = [this.leftpad(date.getHours(), this.leftpad(date.getMinutes()))].join(":");
			return datePart + ' - ' + time
		},
		dateRangeToDays: function (startDate, endDate) {
			var oneDay = 24 * 60 * 60 * 1000;
			if ( !endDate ) {
				endDate = new Date();
			}
			return Math.round(Math.abs(startDate.getTime() - endDate.getTime())/oneDay);
		},		
		masterdata: function(id) {
			if (!id) {
				return "";
			}
			var entry = this.$services.masterdata.entry(id);
			if (entry) {
				return entry.label;
			}
			var category = this.$services.masterdata.category(id);
			if (category) {
				return category.label;
			}
			return this.$services.masterdata.resolve(id);
		},
		number: function(input, amountOfDecimals) {
			amountOfDecimals = amountOfDecimals == null ? 2 : parseInt(amountOfDecimals);
			if (typeof(input) != "number") {
				input = parseFloat(input);
			}
            return input.toFixed(amountOfDecimals);
		},
		stringToHslColor: function (string, saturation, lightness) {
			saturation = 80;
			lightness = 80;
			var hash = 0;
			for (var i = 0; i < string.length; i++) {
				hash = string.charCodeAt(i) + ((hash << 5) - hash);
			}
			var hue = hash % 360;
			return 'hsl('+ hue +', '+ saturation +'%, '+ lightness +'%)';
		},
		address: function (address) {
			return address.street + " " + address.number + " - " + address.postCode + " " + address.city;
		},
		// HELPERS
		leftpad: function (input) {
			return ("0" + input).slice(-2);
		}
	}
}), { name: "nabu.page.services.Formatter" });
