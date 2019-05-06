Vue.service("notifier", {
	data: function () {
		return {
			notifications: [],
			root: null
		}
	},
	activate: function (done) {
		this.initialize();
		
		nabu.page.provide("page-function", {
			id: "notifier.notify",
			async: false,
			implementation: function(input, $services, $value) {
				$services.notifier.notify(input);
			},
			inputs: [{
				"name": "message",
				"required": true,
				"type": "string"
			},{
				"name": "duration",
				"required": false,
				"type": "number"
			},{
				"name": "severity",
				"required": false,
				"type": "string"
			},{
				"name": "description",
				"required": false,
				"type": "string"
			},{
				"name": "code",
				"required": false,
				"type": "string"
			},{
				"name": "icon",
				"required": false,
				"type": "string"
			},{
				"name": "component",
				"required": false,
				"type": "string"
			}]
		});
		
		done();
	},
	methods: {
		error: function (message) {
			if (typeof(message) == "string") {
				message = { message: message };
			}
			message.severity = "error";
			duration = typeof(duration) === "number" ? duration : 10000;
			this.notify(message, duration);
		},
		success: function (message, duration) {
			if (typeof(message) == "string") {
				message = { message: message };
			}
			message.severity = "success";
			duration = typeof(duration) === "number" ? duration : 3000;
			this.notify(message, duration);
		},
		notify: function (message, duration) {
			if (typeof(message) == "string") {
				message = { message: message };
				duration = typeof(duration) === "number" ? duration : 3000;
			}
			else if (!duration) {
				duration = message.duration ? message.duration : 3000;
			}
			
			var notification = new application.components.ANotification({ propsData: message });

			if ( !document.querySelector(".global-notifications")) {
				this.initialize();
			}
			this.$render({
				target: this.root,
				content: notification,
				append: true
			});
			var self = this;
			setTimeout(function() {
				if ( notification.close ) {
					notification.close();
				}
			}, duration);
		},
		initialize: function () {
			this.root = document.createElement("div");
			this.root.setAttribute("class", "global-notifications");
			document.body.appendChild(this.root);
		}
	}
});
