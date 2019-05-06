application.components.ANotification = Vue.component("a-notification", {
	template: "#a-notification",
	props: {
		// kind of notification
		type: {
			type: String,
			default: "generic"
		},
		severity: {
			type: String,
			default: "info",
			validator: function (value) {
				return ["info", "success", "warning", "error"].indexOf(value) >= 0;
			}
		},
		message: {
			type: String
		},
		description: {
			type: String
		},
		context: {
			type: Array,
			default: function () {
				return [];
			}
		},
		code: {
			type: String
		},
		icon: {
			type: String
		},
		component: {
			type: String
		}
	},
	data: function () {
		return {
			created: null
		}
	},
	created: function () {
		this.created = new Date();
	},
	computed: {
		iconClass: function () {
			var map = {
				info: "fa-info-circle",
				success: "fa-check-circle",
				warning: "fa-exclamation-triangle",
				error: "fa-exclamation-triangle"
			};
			return this.icon ? this.icon : "fa " + map[this.severity.toLowerCase()];
		}
	},
	methods: {
		close: function () {
			this.$el.parentElement.removeChild(this.$el);
			this.$destroy();
		}
	}
})
