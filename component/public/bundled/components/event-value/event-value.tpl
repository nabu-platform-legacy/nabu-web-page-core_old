<template id="page-event-value">
	<n-collapsible :title="title" class="page-event-value">
		<n-form-text v-model="container[name].name" label="Event Name"/>
		<div v-for="eventField in container[name].eventFields" class="list-row">
			<n-form-text v-model="eventField.name" label="Field Name"/>
			<n-form-switch v-model="eventField.isFixed" label="Fixed?"/>
			<n-form-combo v-model="eventField.stateValue" v-if="!eventField.isFixed" label="State Value"
				:filter="function(value) { return $services.page.getSimpleKeysFor({properties:$services.page.getAllAvailableParameters(page, null, true)}).filter(function(x) { return !value || x.toLowerCase().indexOf(value.toLowerCase()) >= 0 }) }"/>
			<n-form-text v-model="eventField.fixedValue" v-else label="Fixed Value"/>
			<button @click="container[name].eventFields.splice(container[name].eventFields.indexOf(eventField), 1) & $emit('resetEvents')"><span class="fa fa-trash"></span></button>
		</div>
		<div class="list-actions">
			<button @click="container[name].eventFields.push({name:null,fixedValue:null,isFixed:false,stateValue:null}) & $emit('resetEvents')">Add Event Field</button>
		</div>
	</n-collapsible>
</template>