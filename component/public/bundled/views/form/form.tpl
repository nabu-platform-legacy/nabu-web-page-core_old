<template id="page-form">
	<div class="page-form">
		<n-sidebar @close="configuring = false" v-show="configuring" class="settings">
			<n-form class="layout2">
				<n-collapsible title="Form Settings">
					<n-form-combo label="Operation" :value="operation" :filter="getOperations"
						@input="updateOperation"
						:formatter="function(x) { return x.id }"
						v-if="!cell.state.pageForm"/>
					<n-form-switch label="Page form" v-model="cell.state.pageForm"
						v-if="!cell.state.operation"/>
					<n-form-text v-model="cell.state.title" label="Title"/>
					<n-form-text v-model="cell.state.formId" label="Form Id"/>
					<n-form-text v-model="cell.state.class" label="Form Class"/>
					<n-form-switch v-model="cell.state.immediate" label="Save On Change"/>
					<n-form-text v-model="cell.state.cancel" v-if="!cell.state.immediate" label="Cancel Label"/>
					<n-form-text v-model="cell.state.ok" v-if="!cell.state.immediate" label="Ok Label"/>
					<n-form-text v-model="cell.state.next" v-if="!cell.state.immediate && cell.state.pages.length > 1" label="Next Label"/>
					<n-form-text v-model="cell.state.event" label="Success Event" :timeout="600" @input="$emit('updatedEvents')"/>
					<n-form-switch v-model="cell.state.synchronize" label="Synchronize Changes"/>
					<n-form-switch v-model="cell.state.autofocus" label="Autofocus"/>
					<n-form-switch v-if="cell.state.pages.length >= 2" v-model="cell.state.pageTabs" label="Pages as tabs"/>
					<n-form-switch v-if="cell.state.pages.length >= 2" v-model="cell.state.partialSubmit" label="Allow partial submit"/>
				</n-collapsible>
				<n-collapsible title="Value Binding" v-if="!cell.state.pageForm">
					<div class="list-row">
						<n-form-combo :items="Object.keys(availableParameters)" v-model="autoMapFrom"/>
						<button @click="automap" :disabled="!autoMapFrom">Automap</button>
					</div>
					<n-page-mapper :to="Object.keys(cell.bindings)" :from="availableParameters" 
						v-model="cell.bindings"/>
				</n-collapsible>
				<div v-for="cellPage in cell.state.pages">
					<page-form-configure :title="cellPage.name"
						:schema-resolver="getSchemaFor"
						:groupable="true"
						:edit-name="true"
						:fields="cellPage.fields" 
						:is-list="isList"
						:possible-fields="fieldsToAdd"
						:page="page"
						@input="function(newValue) { cellPage.name = newValue }"
						:cell="cell"/>
					<div class="list-actions" v-if="cell.state.pages.length > 1">
						<button @click="deletePage(cellPage)">Delete {{cellPage.name}}</button>
					</div>
				</div>
				<div class="list-actions">
					<button @click="addPage">Add Form Page</button>
				</div>
			</n-form>
		</n-sidebar>
		<div class="form-tabs" v-if="cell.state.pages.length >= 2 && cell.state.pageTabs">
			<button v-for="page in cell.state.pages" @click="setPage(page)"
				:class="{'is-active': currentPage == page}">{{$services.page.interpret(page.name, self)}}</button>
		</div>
		<h2 v-if="cell.state.title">{{cell.state.title}}</h2>
		<n-form :class="cell.state.class" ref="form" :id="cell.state.formId">
			<n-form-section v-for="group in getGroupedFields(currentPage)" :class="group.group">
				<n-form-section v-for="field in group.fields" :key="field.name + '_section'" v-if="!isPartOfList(field.name) && !isHidden(field)">
					<component v-if="isList(field.name)"
						:is="getProvidedListComponent(field.type)"
						:value="result"
						:page="page"
						:cell="cell"
						:edit="edit"
						:field="field"
						@changed="changed"
						:timeout="cell.state.immediate ? 600 : 0"
						:schema="getSchemaFor(field.name)"/>
					<page-form-field v-else :key="field.name + '_value'" :field="field" :schema="getSchemaFor(field.name)" :value="result[field.name]"
						@input="function(newValue) { $window.Vue.set(result, field.name, newValue); changed(); }"
						:timeout="cell.state.immediate ? 600 : 0"
						:page="page"
						:cell="cell"
						v-focus="cell.state.autofocus == true && currentPage.fields.indexOf(field) == 0"/>
				</n-form-section>
			</n-form-section>
			<footer class="global-actions" v-if="!cell.state.immediate">
				<a class="cancel" href="javascript:void(0)" @click="$emit('close')" :id="cell.state.formId ? cell.state.formId + '_cancel' : null" v-if="cell.state.cancel">{{cell.state.cancel}}</a>
				<button class="primary" :id="cell.state.formId ? cell.state.formId + '_next' : null" @click="nextPage" v-if="cell.state.next && cell.state.pages.indexOf(currentPage) < cell.state.pages.length - 1">{{cell.state.next}}</button>
				<button class="primary" :id="cell.state.formId ? cell.state.formId + '_submit' : null" @click="doIt" v-else-if="cell.state.ok">{{cell.state.ok}}</button>
				<button class="secondary" :id="cell.state.formId ? cell.state.formId + '_submit' : null" @click="doIt" v-if="cell.state.pages.length >= 2 && cell.state.partialSubmit && cell.state.next && cell.state.pages.indexOf(currentPage) < cell.state.pages.length - 1 && cell.state.ok">{{cell.state.ok}}</button>
			</footer>
			<footer>
				<n-messages :messages="messages"/>
			</footer>
		</n-form>
	</div>
</template>

<template id="page-form-field">
	<component
		class="page-form-field"
		:is="getProvidedComponent(field.type)"
		:value="value"
		:page="page"
		:cell="cell"
		:field="field"
		@input="function(newValue) { $emit('input', newValue) }"
		:label="$services.page.interpret(fieldLabel, $self)"
		:timeout="timeout"
		:schema="schema"
		:disabled="isDisabled"/>
</template>

<template id="page-form-configure">
	<n-collapsible class="list" :title="title">
		<div class="root-configuration">
			<n-form-text :value="page.name" label="Page Name" v-if="editName" v-bubble:input/>
		</div>
		<div class="list-actions">
			<button @click="addField">Add Field</button>
		</div>
		<n-collapsible class="field list-item" v-for="field in fields" :title="field.label ? field.label : field.name">
			<page-form-configure-single :field="field" :possible-fields="possibleFields"
				:groupable="groupable"
				:hidable="true"
				:is-list="isList"
				:page="page"
				:schema="schemaResolver(field.name)"
				:cell="cell"/>
			<div class="list-item-actions">
				<button @click="upAll(field)"><span class="fa fa-chevron-circle-left"></span></button>
				<button @click="up(field)"><span class="fa fa-chevron-circle-up"></span></button>
				<button @click="down(field)"><span class="fa fa-chevron-circle-down"></span></button>
				<button @click="downAll(field)"><span class="fa fa-chevron-circle-right"></span></button>
				<button @click="fields.splice(fields.indexOf(field), 1)"><span class="fa fa-trash"></span></button>
			</div>
		</n-collapsible>
	</n-collapsible>
</template>

<template id="page-form-configure-single">
	<div class="page-form-single-field">
		<n-form-combo v-model="field.name" label="Field Name" :items="possibleFields"/>
		<n-form-text v-model="field.label" label="Label" v-if="allowLabel" />
		<n-form-text v-model="field.hidden" label="Hide field if" v-if="hidable" />
		<n-form-text v-model="field.group" label="Field Group" v-if="groupable && !field.joinGroup" />
		<n-form-checkbox v-model="field.joinGroup" label="Join Field Group" v-if="groupable && !field.group" />
		<n-form-text v-model="field.description" label="Description" v-if="allowDescription" />
		<n-form-combo v-model="field.type" label="Type" :items="types"/>
		<n-form-text v-model="field.value" v-if="field.type == 'fixed'" label="Fixed Value"/>
		
		<component v-if="field.type && ['fixed'].indexOf(field.type) < 0"
			:is="getProvidedConfiguration(field.type)"
			:page="page"
			:cell="cell"
			:schema="schema"
			:field="field"/>
			
	</div>
</template>