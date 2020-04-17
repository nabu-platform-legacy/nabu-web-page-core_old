<template id="nabu-page">
	<component :edit="edit" :is="pageTag()" :inline-all="true" class="page" :class="classes" :page="page.name" 
			@drop="dropMenu($event)" @dragover="dragOver($event)">
		<div class="page-menu n-page-menu" v-if="edit && false">
			<button @click="viewComponents = !viewComponents"><span class="fa fa-cubes" title="Add Components"></span></button>
		</div>
		<n-sidebar :inline="true" class="settings" v-if="viewComponents" @close="viewComponents = false" :autocloseable="false">
			<page-components-overview/>
		</n-sidebar>
		<div class="page-edit" v-else-if="$services.page.canEdit() && $services.page.wantEdit && !embedded && !this.$services.page.editing" :draggable="true" 
				@dragstart="dragMenu($event)"
				:class="{'page-component': !page.content.path}"
				:style="{'top': page.content.menuY ? page.content.menuY + 'px' : '0px', 'left': page.content.menuX ? page.content.menuX + 'px' : '0px'}">
			<span>{{page.name}}</span>
			<span class="fa fa-cog" v-if="page.content.path && hasConfigureListener()" @click="triggerConfiguration()"/>
			<span class="fa fa-pencil-alt" @click="goIntoEdit"></span>
			<span class="fa fa-copy" v-route:pages></span>
			<span class="n-icon" :class="'n-icon-' + $services.page.cssStep" v-if="false && $services.page.cssStep"></span>
			<span v-if="page.content.path && $services.language && $services.language.available.length" class="language-selector">
				<span class="current">{{hasLanguageSet() ? $services.language.current.name : "none"}}</span>
				<div class="options">
					<span v-for="language in $services.language.available" @click="$services.language.current = language">{{language.name}}</span>
					<span v-if="$services.language.current && ${environment('development')}" @click="$services.language.current = null">unset</span>
				</div>
			</span>
			<span v-if="false && page.content.path" class="fa fa-sign-out-alt" v-route:logout></span>
			<span class="fa fa-terminal" @click="$window.console.log('Page: ' + page.name, $self)"></span>
			<span class="fa fa-sync" v-if="$services.page.disableReload" @click="$services.page.disableReload = false" title="Start css reload"></span>
			<span class="fa fa-ban" v-else title="Stop css reload" @click="$services.page.disableReload = true"></span>
		</div>
		<div class="page-edit" v-else-if="false && !$services.page.canEdit() && !embedded && $services.page.wantEdit && $services.user && !$services.user.loggedIn"
				:style="{'top': '0px', 'left': '0px'}">
			<span>Login</span>
			<span class="fa fa-sign-in-alt" v-route:login></span>
		</div>
		
		<n-sidebar v-if="edit && page.content.rows" position="left" class="settings sidemenu" :inline="true" :autocloseable="false" ref="sidemenu"
				@close="stopEdit">
			<div class="sidebar-actions">
				<button @click="viewComponents = true"><span class="fa fa-cubes" title="Add Components"></span></button>
				<button @click="configuring = true"><span class="fa fa-cog" title="Configure"></span></button>
				<button @click="addRow(page.content)"><span class="fa fa-plus" title="Add Row"></span></button>
				<button v-if="!embedded" @click="save"><span class="fa fa-save" title="Save"></span></button>
				<button @click="pasteRow" v-if="$services.page.copiedRow"><span class="fa fa-paste"></span></button>
				<button v-if="!embedded && false" @click="stopEdit"><span class="fa fa-sign-out-alt" title="Stop Editing"></span></button>
			</div>
			<div class="last-saved padded-content">
				<label>Last saved:</label><span>{{saved ? $services.formatter.date(saved, 'HH:mm:ss') : 'never' }}</span>
			</div>
			<page-sidemenu v-if="edit && page.content.rows" :rows="page.content.rows" :page="page"
				:selected="selectedItem"
				@select="selectItem"
				@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { page.content.rows.splice(page.content.rows.indexOf(row), 1) }) }"/>
		</n-sidebar>
		
		<n-page-rows v-if="page.content.rows" :rows="page.content.rows" :page="page" :edit="edit"
			:depth="0"
			:parameters="parameters"
			:events="events"
			:ref="page.name + '_rows'"
			:root="true"
			:page-instance-id="pageInstanceId"
			:stop-rerender="stopRerender"
			@select="selectItem"
			@viewComponents="viewComponents = edit"
			@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { page.content.rows.splice(page.content.rows.indexOf(row), 1) }) }"/>
		<n-sidebar :autocloseable="false" v-if="configuring" @close="configuring = false" class="settings" :inline="true">
			<n-form class="layout2">
				<n-collapsible title="General Settings">
					<div class="padded-content">
						<h2>Router<span class="subscript">These settings will determine how the page is routed throughout the application.</span></h2>
						<n-form-text v-model="page.content.category" label="Category" info="The category this page belongs to"/>
						<n-form-text v-model="page.content.path" label="Path" info="The path this page can be found on, if you don't want to expose it via a dedicated path, leave this empty.<br/><br/> You can use the following syntax to define path variables:<br/>/path/to/{myVariable}/is"/>
						<n-form-text v-model="page.content.title" label="Title"/>
						<n-form-combo label="Page Parent" :filter="filterRoutes" v-model="page.content.pageParent"/>
						<n-form-text v-model="page.content.defaultAnchor" label="Content Anchor"/>
						<n-form-text v-model="page.content.autoRefresh" label="Auto-refresh"/>
						<n-form-switch label="Is slow" v-if="!page.content.initial" v-model="page.content.slow" info="Is a slow route"/>
						<n-form-switch label="Route Error in Self" v-model="page.content.errorInSelf"/>
						
						<h2>Rendering<span class="subscript">These settings will influence how the page is rendered.</span></h2>
						<n-form-combo label="Page Type" :filter="getPageTypes" v-model="page.content.pageType"/>
						<n-form-text v-model="page.content.class" label="CSS Class"/>
						
						<h2>Security<span class="subscript">You can configure additional security on a page to limit access.</span></h2>
						
						<div class="n-form-component n-form-actions">
							<div class="n-form-label-wrapper">
								<label>Roles</label>
								<n-info>Add roles that are allowed to access this page. If no roles are configured, everyone is allowed.<br/><br/>
									You can use pseudo roles like $user to indicate anyone who is logged in or $guest anyone who is not.</n-info>
							</div>
							<div class="actions">
								<button @click="page.content.roles ? page.content.roles.push('') : $window.Vue.set(page.content, 'roles', [''])">Add Role</button>
							</div>
						</div>
						<div class="list" v-if="page.content.roles">
							<div v-for="i in Object.keys(page.content.roles)" class="list-row">
								<n-form-text v-model="page.content.roles[i]" placeholder="Role e.g. $user, $guest, ..."/>
								<button @click="page.content.roles.splice(i)"><span class="fa fa-trash"></span></button>
							</div>
						</div>
					</div>
				</n-collapsible>
				<n-collapsible title="Initial State" class="list">
					<div class="list-actions">
						<button @click="addState"><span class="fa fa-plus"></span>Initial State</button>
						<button @click="addApplicationState"><span class="fa fa-plus"></span>Application State</button>
						<button @click="function() { if (page.content.stateErrors) page.content.stateErrors.push({}); else $window.Vue.set(page.content, 'stateErrors', [{}]) }"><span class="fa fa-plus"></span>Error Route</button>
					</div>
					<n-collapsible class="list-item" :title="state.name" v-for="state in page.content.states">
						<n-form-text :value="state.name" @input="function(newValue) { if (!validateStateName(newValue).length) state.name = newValue; }" label="Name" :required="true" :validator="validateStateName"/>
						<div v-if="state.inherited">
							<n-form-combo v-model="state.applicationName" :filter="$services.page.getApplicationStateNames" label="Application State" />
						</div>
						<div v-else>
							<n-form-combo :value="state.operation" :filter="getStateOperations" label="Operation" @input="function(newValue) { setStateOperation(state, newValue) }"/>
							<n-page-mapper v-if="state.operation && Object.keys($services.page.getPageParameters(page)).length" :to="getOperationParameters(state.operation)"
								:from="{page:$services.page.getPageParameters(page)}" 
								v-model="state.bindings"/>
						</div>
						<page-event-value :page="page" :container="state" title="Successful Update Event" name="updateEvent" @resetEvents="resetEvents"/>
						<div class="list-item-actions">
							<button @click="page.content.states.splice(page.content.states.indexOf(state), 1)"><span class="fa fa-trash"></span></button>
						</div>
						<div class="list" v-if="state.refreshOn">
							<div v-for="i in Object.keys(state.refreshOn)" class="list-row">
								<n-form-combo v-model="state.refreshOn[i]" :filter="getAvailableEvents" placeholder="event"/>
								<span @click="state.refreshOn.splice(i)" class="fa fa-times"></span>
							</div>
						</div>
						<div class="list-actions">
							<button @click="state.refreshOn ? state.refreshOn.push('') : $window.Vue.set(state, 'refreshOn', [''])"><span class="fa fa-plus"></span>Refresh Event</button>
						</div>
					</n-collapsible>
					<div v-if="page.content.stateErrors" class="list">
						<div v-for="stateError in page.content.stateErrors">
							<n-form-text v-model="stateError.code" label="Error Code"/>
							<n-form-combo label="Error Page" :filter="filterRoutes" v-model="stateError.route"/>
						</div>
					</div>
				</n-collapsible>
				<n-collapsible title="Initial Events" class="list">
					<div class="list-actions">
						<button @click="addInitialEvent">Add Initial Event</button>
					</div>
					<n-collapsible class="list-item" :title="event ? $window.nabu.page.event.getName(event, 'definition') : 'unnamed'" v-for="event in page.content.initialEvents">
						<n-form-text v-model="event.condition" label="Condition"/>
						<n-form-text v-model="event.timeout" label="Repeat Interval (ms)"/>
						<page-event-value :page="page" :container="event" title="Initial Event" name="definition" @resetEvents="resetEvents"/>
						<div class="list-item-actions">
							<button @click="page.content.initialEvents.splice(page.content.initialEvents.indexOf(event), 1)"><span class="fa fa-trash"></span></button>
						</div>
					</n-collapsible>
				</n-collapsible>
				<n-collapsible title="Computed State" class="list" v-if="false">
					<div class="list-actions">
						<button @click="addComputed">Add Computed State</button>
					</div>
					<div v-if="page.content.computed">
						<n-collapsible class="list-item" :title="state.name" v-for="state in page.content.computed">
							<n-form-text :value="state.name" @input="function(newValue) { if (!validateStateName(newValue).length) state.name = newValue; }" label="Name" :required="true" :validator="validateStateName"/>
							<n-page-mapper v-if="state.name" :to="[state.name]"
								:from="availableParameters" 
								v-model="state.bindings"/>
						</n-collapsible>
					</div>
				</n-collapsible>
				
				<n-collapsible title="Query Parameters">
					<div class="list-actions">
						<button @click="page.content.query.push('unnamed')">Add Query Parameter</button>
					</div>
					<div class="padded-content">
						<div class="list-row" v-for="i in Object.keys(page.content.query)">
							<n-form-text v-model="page.content.query[i]"/>
							<span @click="removeQuery(i)" class="fa fa-times"></span>
						</div>
					</div>
				</n-collapsible>
				<n-collapsible title="Page Parameters" class="list">
					<div class="list-actions">
						<button @click="addPageParameter">Add Page Parameter</button>
					</div>
					<n-collapsible class="list-item" v-for="parameter in page.content.parameters" :title="parameter.name">
						<n-form-text v-model="parameter.name" :required="true" label="Name"/>
						<n-form-combo v-model="parameter.type" label="Type" :nillable="false" :filter="getParameterTypes"/>
						<n-form-combo v-model="parameter.format" label="Format" v-if="parameter.type == 'string'" :items="['date-time', 'uuid', 'uri', 'date', 'password']"/>
						<n-form-text v-model="parameter.default" label="Default Value" />
						<n-form-switch v-if="false" v-model="parameter.global" label="Is translation global?"/>
						<div class="list-row" v-for="i in Object.keys(parameter.listeners)">
							<n-form-combo v-model="parameter.listeners[i].to" :filter="function() { return $services.page.getAllAvailableKeys(page) }" />
							<n-form-combo v-model="parameter.listeners[i].field" v-if="parameter.type && parameter.type.indexOf('.') >= 0" :filter="listFields.bind($this, parameter.type)" />
							<button @click="parameter.listeners.splice(i, 1)"><span class="fa fa-times"></span></button>
						</div>
						<div v-if="parameter.resetListeners">
							<div class="list-row" v-for="i in Object.keys(parameter.resetListeners)">
								<n-form-combo v-model="parameter.resetListeners[i].to" :filter="function() { return $services.page.getAllAvailableKeys(page) }" />
								<n-form-combo v-model="parameter.resetListeners[i].field" v-if="false && parameter.type && parameter.type.indexOf('.') >= 0" :filter="listFields.bind($this, parameter.type)" description="Not yet"  />
								<button @click="parameter.resetListeners.splice(i, 1)"><span class="fa fa-times"></span></button>
							</div>
						</div>
						<div class="list-item-actions">
							<button @click="parameter.listeners.push({to:null, field: null})"><span class="fa fa-plus"></span>Update Listener</button>
							<button @click="parameter.resetListeners ? parameter.resetListeners.push({to:null, field: null}) : $window.Vue.set(parameter, 'resetListeners', [{to:null,field:null}])" v-if="parameter.default"><span class="fa fa-plus"></span>Reset Listener</button>
							<button @click="page.content.parameters.splice(page.content.parameters.indexOf(parameter), 1)"><span class="fa fa-trash"></span></button>	
						</div>
						<div v-if="parameter.type && parameter.type.indexOf('.') > 0">
							<div class="list-actions">
								<button @click="parameter.defaults ? parameter.defaults.push({query:null,value:null}) : $window.Vue.set(parameter, 'defaults', [{query:null,value:null}])">Add Default Value</button>
							</div>
							<div v-if="parameter.defaults">
								<n-form-section class="list-row" v-for="defaultValue in parameter.defaults">
									<n-form-combo v-model="defaultValue.query" placeholder="Query" :filter="listFields.bind($this, parameter.type)"/>
									<n-form-text v-model="defaultValue.value" placeholder='Value'/>
									<button @click="parameter.defaults.splice(parameter.defaults.indexOf(defaultValue), 1)"><span class="fa fa-trash"></span></button>
								</n-form-section>
							</div>
						</div>
					</n-collapsible>
				</n-collapsible>
				
				<n-collapsible title="Triggers" class="list">
					<div class="list-actions">
						<button @click="addAction">Add Trigger</button>
					</div>
					<n-collapsible class="list-item" :title="(action.on ? '[' + action.on + '] ' : '') + action.name" v-for="action in page.content.actions">
						<n-form-text v-model="action.name" label="Name" :required="true" :timeout="600"/>
						<n-form-text v-model="action.confirmation" label="Confirmation Message" :timeout="600"/>
						<n-form-combo v-model="action.on" label="Trigger On" :filter="getAvailableEvents"/>
						<n-form-text v-model="action.condition" label="Condition" v-if="action.on" :timeout="600"/>
						<n-form-text v-model="action.scroll" label="Scroll to" v-if="!action.operation && !action.function" :timeout="600"/>
						<n-form-combo v-model="action.route" v-if="!action.operation && !action.url && !action.function" label="Redirect" :filter="filterRoutes"/>
						<n-form-combo v-model="action.anchor" v-if="action.url || action.route || (action.operation && isGet(action.operation))" label="Anchor" :filter="function(value) { return value ? [value, '$blank', '$window'] : ['$blank', '$window'] }"/>
						<n-form-combo :key="'operation' + page.content.actions.indexOf(action)" v-model="action.operation" v-if="!action.route && !action.scroll && !action.url && !action.function" label="Operation" :filter="getOperations" />
						<n-form-text v-model="action.timeout" v-if="action.operation" label="Action Timeout" info="You can emit an event if the action takes too long" :timeout="600"/>
						<page-event-value class="no-more-padding"  v-if="action.operation && action.timeout" :page="page" :container="action" title="Timeout Event" name="timeoutEvent" @resetEvents="resetEvents"/>
						<n-form-combo v-model="action.function" v-if="!action.route && !action.scroll && !action.url && !action.operation" label="Function" :filter="$services.page.listFunctions" />
						<n-form-text v-model="action.url" label="URL" v-if="!action.route && !action.operation && !action.scroll && !action.function" :timeout="600"/>
						<page-event-value class="no-more-padding" :page="page" :container="action" title="Chain Event" name="chainEvent" @resetEvents="resetEvents"/>
						<n-form-switch v-if="action.operation || action.function" v-model="action.isSlow" label="Is slow operation?"/>
						<n-form-text v-if="action.operation" v-model="action.event" label="Success Event" @input="resetEvents()" :timeout="600"/>
						<n-form-text v-if="action.operation" v-model="action.errorEvent" label="Error Event" @input="resetEvents()" :timeout="600"/>
						<n-form-switch v-if="action.operation" v-model="action.expandBindings" label="Field level bindings"/>
						<div class="simple-row" v-if="action.operation && !action.route && action.expandBindings">
							<n-form-combo 
								:items="Object.keys(availableParameters)" v-model="autoMapFrom"/>
							<button @click="automap(action)" :disabled="!autoMapFrom">Automap</button>
						</div>
						<n-page-mapper v-if="action.operation && !action.route && !action.expandBindings" :to="getOperationParameters(action.operation)"
							:from="availableParameters" 
							v-model="action.bindings"/>
						<n-page-mapper v-else-if="action.operation && !action.route && action.expandBindings" :to="getOperationParameters(action.operation, true)"
							:from="availableParameters" 
							v-model="action.bindings"/>
						<n-page-mapper v-if="action.route" :to="$services.page.getRouteParameters($services.router.get(action.route))"
							:from="availableParameters" 
							v-model="action.bindings"/>
						<n-page-mapper v-if="action.function && !action.operation && !action.route" :to="$services.page.getFunctionInput(action.function)"
							:from="availableParameters" 
							v-model="action.bindings"/>
							
						<div class="list-item-actions">
							<button @click="page.content.actions.splice(page.content.actions.indexOf(action), 1)"><span class="fa fa-trash"></span></button>
						</div>
						
						<div v-if="action.eventResets">
							<div class="list-row" v-for="i in Object.keys(action.eventResets)">
								<n-form-combo v-model="action.eventResets[i]" :filter="getAvailableEvents"/>
								<span @click="action.eventResets.splice(i, 1)" class="fa fa-times"></span>
							</div>
						</div>
						<div class="list-item-actions">
							<button @click="addEventReset(action)"><span class="fa fa-plus"></span>Event To Reset</button>
						</div>
					</n-collapsible>
				</n-collapsible>	
				<n-collapsible title="Analysis" class="list">
					<div class="list-actions">
						<button @click="addAnalysis">Add Analysis</button>
					</div>
					<n-collapsible class="list-item" :title="(analysis.on ? '[' + analysis.on + '] ' : '') + (analysis.chainEvent && analysis.chainEvent.name ? analysis.chainEvent.name : 'unnamed')" v-for="analysis in page.content.analysis">
						<n-form-combo v-model="analysis.on" label="Trigger On" :filter="getAvailableEvents"/>
						<n-form-text v-model="analysis.condition" label="Condition" v-if="analysis.on" :timeout="600"/>
						<page-event-value :inline="true" class="no-more-padding" :page="page" :container="analysis" title="Analysis Event" name="chainEvent" @resetEvents="resetEvents"/>
					</n-collapsible>
				</n-collapsible>
				<n-collapsible title="Publish Global Events" class="list">
					<div class="list-actions">
						<button @click="addGlobalEvent">Add Global Event</button>
					</div>
					<div class="padded-content" v-if="page.content.globalEvents">
						<n-form-section class="list-row" v-for="i in Object.keys(page.content.globalEvents)">
							<n-form-combo v-model="page.content.globalEvents[i].localName"
								label="Local Name"
								:filter="getAvailableEvents"/>
							<n-form-text v-model="page.content.globalEvents[i].globalName" 
								label="Global Name"
								:placeholder="page.content.globalEvents[i].localName"/>
							<span @click="page.content.globalEvents.splice(i, 1)" class="fa fa-times"></span>
						</n-form-section>
					</div>
				</n-collapsible>
				<n-collapsible title="Subscribe Global Events" class="list">
					<div class="list-actions">
						<button @click="addGlobalEventSubscription">Add Global Event</button>
					</div>
					<div class="padded-content" v-if="page.content.globalEventSubscriptions">
						<n-form-section class="list-row" v-for="i in Object.keys(page.content.globalEventSubscriptions)">
							<n-form-combo v-model="page.content.globalEventSubscriptions[i].globalName"
								label="Global Name"
								:items="$window.Object.keys($services.page.getGlobalEvents())"/>
							<n-form-text v-model="page.content.globalEventSubscriptions[i].localName" 
								label="Local Name"
								:placeholder="page.content.globalEventSubscriptions[i].globalName"/>
							<span @click="page.content.globalEventSubscriptions.splice(i, 1)" class="fa fa-times"></span>
						</n-form-section>
					</div>
				</n-collapsible>
				<component v-for="plugin in plugins" :is="plugin.configure" 
					:page="page" 
					:edit="edit"/>
			</n-form>
		</n-sidebar>
		<div class="page-menu n-page-menu" v-if="edit && false">
			<button @click="viewComponents = !viewComponents"><span class="fa fa-cubes" title="Add Components"></span></button>
		</div>
	</component>
</template>

<template id="page-rows">
	<component :is="rowsTag()" class="page-rows">
		<component :is="rowTagFor(row)" v-for="row in getCalculatedRows()" class="page-row" :id="page.name + '_' + row.id" 
				:class="$window.nabu.utils.arrays.merge(['page-row-' + row.cells.length, row.class ? row.class : null, {'collapsed': row.collapsed}, {'empty': !row.cells || !row.cells.length } ], rowClasses(row))"                    
				:key="'page_' + pageInstanceId + '_row_' + row.id"
				:row-key="'page_' + pageInstanceId + '_row_' + row.id"
				v-if="edit || shouldRenderRow(row)"
				:style="rowStyles(row)"
				@drop="drop($event, row)" 
				@dragend="$services.page.clearDrag($event)"
				@dragover="dragOver($event, row)"
				@dragexit="dragExit($event, row)"
				@mouseout="mouseOut($event, row)"
				@mouseover="mouseOver($event, row)"
				@click.ctrl="goto($event, row)"
				@click.alt="$emit('select', row) && $emit('viewComponents')"
				v-bind="getRendererProperties(row)">
			<div v-if="false && (edit || $services.page.wantEdit || row.wantVisibleName) && row.name && !row.collapsed" :style="getRowEditStyle(row)" class="row-edit-label"
				:class="'direction-' + (row.direction ? row.direction : 'horizontal')"><span>{{row.name}}</span></div>
			<div class="page-row-menu n-page-menu" v-if="edit" @mouseenter="menuHover" @mouseleave="menuUnhover">
				<label v-if="false && row.collapsed">{{row.name}}</label>
				<button v-if="!row.collapsed" :style="rowButtonStyle(row)" @click="configuring = row.id"><span class="fa fa-cog"></span></button
				><button v-if="!row.collapsed" :style="rowButtonStyle(row)" @click="up(row)"><span class="fa fa-chevron-circle-up"></span></button
				><button v-if="!row.collapsed" :style="rowButtonStyle(row)" @click="down(row)"><span class="fa fa-chevron-circle-down"></span></button
				><button v-if="!row.collapsed" :style="rowButtonStyle(row)" @click="addCell(row)"><span class="fa fa-plus" title="Add Cell"></span></button
				><button v-if="!row.collapsed" :style="rowButtonStyle(row)" @click="copyRow(row)"><span class="fa fa-copy" title="Copy Row"></span></button
				><button v-if="!row.collapsed && $services.page.copiedCell" :style="rowButtonStyle(row)" @click="pasteCell(row)"><span class="fa fa-paste" title="Paste Cell"></span></button
				><button v-if="!row.collapsed" :style="rowButtonStyle(row)" @click="$emit('removeRow', row)"><span class="fa fa-times" title="Remove Row"></span></button
				><button :style="rowButtonStyle(row)" @click="row.collapsed = !row.collapsed"><span class="fa" :class="{'fa-minus-square': !row.collapsed, 'fa-plus-square': row.collapsed }"></span></button>
			</div>
			<div v-if="row.customId" class="custom-row custom-id" :id="row.customId"><!-- to render stuff in without disrupting the other elements here --></div>
			<component :is="cellTagFor(row, cell)" :style="getStyles(cell)" v-for="cell in getCalculatedCells(row)" v-if="shouldRenderCell(row, cell)" v-show="!edit || !row.collapsed"
					:id="page.name + '_' + row.id + '_' + cell.id" 
					:class="$window.nabu.utils.arrays.merge([{'clickable': hasCellClickEvent(cell)}, {'page-cell': edit || !cell.target || cell.target == 'page', 'page-prompt': cell.target == 'prompt' || cell.target == 'sidebar' || cell.target == 'absolute' }, cell.class ? cell.class : null, {'has-page': hasPageRoute(cell), 'is-root': root}, {'empty': !cell.alias && (!cell.rows || !cell.rows.length) } ], cellClasses(cell))"                         
					:key="cellId(cell)"
					:cell-key="'page_' + pageInstanceId + '_cell_' + cell.id"
					@click="clickOnCell(cell)"
					@click.ctrl="goto($event, row, cell)"
					@mouseout="mouseOut($event, row, cell)"
					@mouseover="mouseOver($event, row, cell)"
					v-bind="getRendererProperties(cell)">
				<div v-if="false && (edit || $services.page.wantEdit) && cell.name" :style="getCellEditStyle(cell)" class="cell-edit-label"><span>{{cell.name}}</span></div>
				<div v-if="cell.customId" class="custom-cell custom-id" :id="cell.customId"><!-- to render stuff in without disrupting the other elements here --></div>
				<n-sidebar :autocloseable="false" v-if="configuring == cell.id" @close="configuring = null" class="settings" key="cell-settings" :inline="true">
					<div class="sidebar-actions">
						<button @click="configuring = null; configure(cell)" v-if="cell.alias && hasConfigure(cell)"><span class="fa fa-cog" title="Configure Cell Content"></span></button
						><button @click="left(row, cell)" v-if="row.cells.length >= 2"><span class="fa fa-chevron-circle-left"></span></button
						><button @click="right(row, cell)" v-if="row.cells.length >= 2"><span class="fa fa-chevron-circle-right"></span></button
						><button @click="addRow(cell)"><span class="fa fa-plus" title="Add Row"></span></button
						><button @click="copyCell(cell)"><span class="fa fa-copy" title="Copy Cell"></span></button
						><button @click="pasteRow(cell)" v-if="$services.page.copiedRow"><span class="fa fa-paste" title="Paste Row"></span></button
						><button @click="removeCell(row.cells, cell)"><span class="fa fa-times" title="Remove Cell"></span></button>
					</div>
					<n-form class="layout2" key="cell-form">
						<div class="padded-content">
							<n-form-combo label="Content Route" :filter="filterRoutes" v-model="cell.alias"
								:key="'page_' + pageInstanceId + '_' + cell.id + '_alias'"
								:required="true"
								info="The content we want to route in the cell"/>
						</div>
						<n-form-section>
							<n-collapsible title="Cell Settings" key="cell-settings">
								<div class="padded-content">
									<h2>Content<span class="subscript">Choose the content you want to add to your cell</span></h2>
									<n-form-text label="Cell Name" v-model="cell.name" info="A descriptive name"/>
									<n-page-mapper v-if="cell.alias" 
										:key="'page_' + pageInstanceId + '_' + cell.id + '_mapper'"
										:to="getRouteParameters(cell)"
										:from="getAvailableParameters(cell)" 
										v-model="cell.bindings"/>
									<n-form-text label="Condition" v-model="cell.condition" info="If you fill in a condition, the cell will only render the content if the condition evaluates to true"/>
										
									<h2>Additional<span class="subscript">Configure some additional settings for this cell</span></h2>
									<n-form-text label="Cell Id" v-model="cell.customId" info="If you set a custom id for this cell, a container will be rendered in this cell with that id. This can be used for targeting with specific content."/>
									<n-form-text label="Cell Width" v-model="cell.width" info="By default flex is used to determine cell size, you can either configure a number for flex or choose to go for a fixed value"/>
									<n-form-text label="Cell Height" v-model="cell.height" info="You can configure any height, for example 200px"/>
									<n-form-text label="Cell Reference" v-model="cell.ref" info="A reference you can use to retrieve this cell programmatically"/>
									<n-form-combo label="Cell Renderer" v-model="cell.renderer" :items="getRenderers('cell')" :formatter="function(x) { return x.name }" 
										:extracter="function(x) { return x.name }" info="Use a specific renderer for this cell"/>
									<n-form-section v-if="cell.renderer">
										<n-form-text v-for="property in getRendererPropertyKeys(cell)" :label="property" v-model="cell.rendererProperties[property]"/>
									</n-form-section>
									<n-form-switch label="Stop Rerender" v-model="cell.stopRerender" info="All components are reactive to their input, you can however prevent rerendering by settings this to true"/>
									<div v-if="$services.page.devices.length">
										<div class="list-actions">
											<button @click="addDevice(cell)">Add device rule</button>
										</div>
										<div v-if="cell.devices">
											<div class="list-row" v-for="device in cell.devices">
												<n-form-combo v-model="device.operator" :items="['>', '>=', '<', '<=', '==']"/>
												<n-form-combo v-model="device.name" 
													:filter="suggestDevices"/>
												<span @click="cell.devices.splice(cell.devices.indexOf(device), 1)" class="fa fa-times"></span>
											</div>
										</div>
									</div>
								</div>
							</n-collapsible>
							<n-collapsible title="Repeat" class="list" v-if="cell.instances && $services.page.getAllArrays(page, cell.id).length">
								<div class="list-actions" v-if="!Object.keys(cell.instances).length">
									<button @click="addInstance(cell)">Add Repeat</button>
								</div>
								<n-collapsible class="list-item" :title="key" v-for="key in Object.keys(cell.instances)">
									<n-form-text :value="key" label="Name" :required="true" :timeout="600" @input="function(value) { renameInstance(cell, key, value) }"/>
									<n-form-combo v-model="cell.instances[key]" label="Array" :filter="function() { return $services.page.getAllArrays(page, cell.id) }" />
									<div class="list-item-actions">
										<span @click="removeInstance(cell, key)" class="fa fa-times"></span>
									</div>
								</n-collapsible>
							</n-collapsible>
							<n-collapsible title="Eventing" key="cell-events">
								<div class="padded-content">
									<n-form-switch label="Closeable" v-model="cell.closeable" v-if="!cell.on"/>
									<n-form-combo label="Show On" v-model="cell.on" :filter="getAvailableEvents" v-if="!cell.closeable"/>
									<n-form-combo label="Target" :items="['page', 'sidebar', 'prompt', 'absolute']" v-model="cell.target"/>
									<n-form-switch label="Prevent Auto Close" v-model="cell.preventAutoClose" v-if="cell.target == 'sidebar'"/>
									<n-form-switch label="Optimize (may result in stale content)" v-model="cell.optimizeVueKey" v-if="cell.on"/>
									<n-form-text label="Top" v-model="cell.top" v-if="cell.target == 'absolute'"/>
									<n-form-text label="Bottom" v-model="cell.bottom" v-if="cell.target == 'absolute'"/>
									<n-form-text label="Left" v-model="cell.left" v-if="cell.target == 'absolute'"/>
									<n-form-text label="Right" v-model="cell.right" v-if="cell.target == 'absolute'"/>
									<n-form-text label="Minimum Width" v-model="cell.minWidth" v-if="cell.target == 'absolute'"/>
									<n-form-switch label="Position fixed?" v-model="cell.fixed" v-if="cell.target == 'absolute'"/>
									<n-form-switch label="Autoclose" v-model="cell.autoclose" v-if="cell.target == 'absolute'"/>
								</div>								
								<page-event-value :page="page" :container="cell" title="Click Event" name="clickEvent" @resetEvents="resetEvents"/>
							</n-collapsible>
							<n-collapsible title="Styling">
								<div class="padded-content">
									<n-form-text label="Class" v-model="cell.class"/>
								</div>
								<div class="list-actions">
									<button @click="cell.styles == null ? $window.Vue.set(cell, 'styles', [{class:null,condition:null}]) : cell.styles.push({class:null,condition:null})"><span class="fa fa-plus"></span>Style</button>
								</div>
								<div class="padded-content" v-if="cell.styles">
									<n-form-section class="list-row" v-for="style in cell.styles">
										<n-form-text v-model="style.class" label="Class"/>
										<n-form-text v-model="style.condition" label="Condition" class="vertical"/>
										<span @click="cell.styles.splice(cell.styles.indexOf(style), 1)" class="fa fa-times"></span>
									</n-form-section>
								</div>
							</n-collapsible>
						</n-form-section>
					</n-form>
				</n-sidebar>
				<div class="page-cell-menu n-page-menu" v-if="edit" @mouseenter="menuHover" @mouseleave="menuUnhover">
					<button @click="left(row, cell)" v-if="row.cells.length >= 2"><span class="fa fa-chevron-circle-left"></span></button
					><button @click="right(row, cell)" v-if="row.cells.length >= 2"><span class="fa fa-chevron-circle-right"></span></button
					><button @click="cellUp(row, cell)" v-if="false"><span class="fa fa-chevron-circle-up"></span></button
					><button @click="cellDown(row, cell)" v-if="false"><span class="fa fa-chevron-circle-down"></span></button
					><button @click="addRow(cell)"><span class="fa fa-plus" title="Add Row"></span></button
					><button @click="removeCell(row.cells, cell)"><span class="fa fa-times" title="Remove Cell"></span></button
					><button @click="copyCell(cell)"><span class="fa fa-copy" title="Copy Cell"></span></button
					><button @click="pasteRow(cell)" v-if="$services.page.copiedRow"><span class="fa fa-paste" title="Paste Row"></span></button
					><button @click="configuring = cell.id"><span class="fa fa-magic" title="Set Cell Content"></span></button
					><button @click="configure(cell)" v-if="cell.alias"><span class="fa fa-cog" title="Configure Cell Content"></span></button>
				</div>
				
				<div v-if="edit">
					<div v-if="cell.alias" :key="'page_' + pageInstanceId + '_rendered_' + cell.id" v-route-render="{ alias: cell.alias, parameters: getParameters(row, cell), mounted: getMountedFor(cell, row), rerender: function() { return false } }"></div>
					<n-page-rows v-if="cell.rows && cell.rows.length" :rows="cell.rows" :page="page" :edit="edit"
						:depth="depth + 1"
						:parameters="parameters"
						:events="events"
						:ref="page.name + '_' + cell.id + '_rows'"
						:local-state="getLocalState(row, cell)"
						:page-instance-id="pageInstanceId"
						:stop-rerender="stopRerender"
						v-bubble:viewComponents
						@select="function(item) { $emit('select', item) }"
						@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { cell.rows.splice(cell.rows.indexOf(row), 1) }) }"/>
				</div>
				<template v-else-if="shouldRenderCell(row, cell)">
					<n-sidebar v-if="cell.target == 'sidebar'" @close="close(cell)" :popout="false" :autocloseable="!cell.preventAutoClose" class="content-sidebar" :style="getSideBarStyles(cell)">
						<div @keyup.esc="close(cell)" :key="'page_' + pageInstanceId + '_rendered_' + cell.id" v-if="cell.alias" v-route-render="{ alias: cell.alias, parameters: getParameters(row, cell), mounted: getMountedFor(cell, row), rerender: function() { return !stopRerender && !cell.stopRerender } }"></div>
						<n-page-rows v-if="cell.rows && cell.rows.length" :rows="cell.rows" :page="page" :edit="edit"
							:depth="depth + 1"
							:parameters="parameters"
							:events="events"
							:ref="page.name + '_' + cell.id + '_rows'"
							:local-state="getLocalState(row, cell)"
							:page-instance-id="pageInstanceId"
							:stop-rerender="stopRerender"
							@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { cell.rows.splice(cell.rows.indexOf(row), 1) }) }"/>
					</n-sidebar>
					<n-prompt v-else-if="cell.target == 'prompt'" @close="close(cell)">
						<div @keyup.esc="close(cell)" :key="'page_' + pageInstanceId + '_rendered_' + cell.id" v-if="cell.alias" v-route-render="{ alias: cell.alias, parameters: getParameters(row, cell), mounted: getMountedFor(cell, row), rerender: function() { return !stopRerender && !cell.stopRerender } }"></div>
						<n-page-rows v-if="cell.rows && cell.rows.length" :rows="cell.rows" :page="page" :edit="edit"
							:depth="depth + 1"
							:parameters="parameters"
							:events="events"
							:ref="page.name + '_' + cell.id + '_rows'"
							:local-state="getLocalState(row, cell)"
							:page-instance-id="pageInstanceId"
							:stop-rerender="stopRerender"
							@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { cell.rows.splice(cell.rows.indexOf(row), 1) }) }"/>
					</n-prompt>
					<n-absolute :fixed="cell.fixed" :style="{'min-width': cell.minWidth}" :autoclose="cell.autoclose" v-else-if="cell.target == 'absolute'" @close="close(cell)" :top="cell.top" :bottom="cell.bottom" :left="cell.left" :right="cell.right">          
						<div @keyup.esc="close(cell)" :key="'page_' + pageInstanceId + '_rendered_' + cell.id" v-if="cell.alias" v-route-render="{ alias: cell.alias, parameters: getParameters(row, cell), mounted: getMountedFor(cell, row), rerender: function() { return !stopRerender && !cell.stopRerender } }"></div>
						<n-page-rows v-if="cell.rows && cell.rows.length" :rows="cell.rows" :page="page" :edit="edit"
							:depth="depth + 1"
							:parameters="parameters"
							:events="events"
							:ref="page.name + '_' + cell.id + '_rows'"
							:local-state="getLocalState(row, cell)"
							:page-instance-id="pageInstanceId"
							:stop-rerender="stopRerender"
							@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { cell.rows.splice(cell.rows.indexOf(row), 1) }) }"/>						
					</n-absolute>
					<template v-else>
						<div :key="'page_' + pageInstanceId + '_rendered_' + cell.id" v-if="cell.alias" v-route-render="{ alias: cell.alias, parameters: getParameters(row, cell), mounted: getMountedFor(cell, row), rerender: function() { return !stopRerender && !cell.stopRerender } }"></div>
						<n-page-rows v-if="cell.rows && cell.rows.length" :rows="cell.rows" :page="page" :edit="edit"
							:depth="depth + 1"
							:parameters="parameters"
							:events="events"
							:ref="page.name + '_' + cell.id + '_rows'"
							:local-state="getLocalState(row, cell)"
							:page-instance-id="pageInstanceId"
							:stop-rerender="stopRerender"
							@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { cell.rows.splice(cell.rows.indexOf(row), 1) }) }"/>
					</template>
				</template>
			</component>
			<n-sidebar :autocloseable="false" v-if="configuring == row.id" @close="configuring = null" class="settings" :inline="true" >
				<div class="sidebar-actions">
					<button @click="up(row)"><span class="fa fa-chevron-circle-up"></span></button
					><button @click="down(row)"><span class="fa fa-chevron-circle-down"></span></button
					><button @click="addCell(row)"><span class="fa fa-plus" title="Add Cell"></span></button
					><button @click="copyRow(row)"><span class="fa fa-copy" title="Copy Row"></span></button
					><button v-if="$services.page.copiedCell" @click="pasteCell(row)"><span class="fa fa-paste" title="Paste Cell"></span></button
					><button @click="$emit('removeRow', row)"><span class="fa fa-times" title="Remove Row"></span></button>
				</div>
				<n-form class="layout2">
					<div class="padded-content">
						<n-form-text label="Row Name" v-model="row.name" info="A descriptive name"/>
					</div>
					<n-collapsible title="Row Settings">
						<div class="padded-content">
							<h2>Rendering<span class="subscript">Choose how this row will be rendered</span></h2>
							<n-form-combo label="Direction" v-model="row.direction" :items="['horizontal', 'vertical']"/>
							<n-form-combo label="Alignment" v-model="row.align" :items="['center', 'flex-start', 'flex-end', 'stretch', 'baseline']"/>
							<n-form-combo label="Justification" v-model="row.justify" :items="['center', 'flex-start', 'flex-end', 'space-between', 'space-around', 'space-evenly']"/>
							<n-form-ace label="Condition" v-model="row.condition" class="vertical"/>
							
							<h2>Additional<span class="subscript">Configure some additional settings for this row</span></h2>
							<n-form-text label="Row Id" v-model="row.customId" info="If you set a custom id for this row, a container will be rendered in this row with that id. This can be used for targeting with specific content."/>
							<n-form-combo label="Row Renderer" v-model="row.renderer" :items="getRenderers('row')"  :formatter="function(x) { return x.name }" :extracter="function(x) { return x.name }"/>
							<n-form-section v-if="row.renderer">
								<n-form-text v-for="property in getRendererPropertyKeys(row)" :label="property" v-model="row.rendererProperties[property]"/>
							</n-form-section>
							<div v-if="$services.page.devices.length">
								<div class="list-actions">
									<button @click="addDevice(row)">Add device rule</button>
								</div>
								<div v-if="row.devices">
									<div class="list-row" v-for="device in row.devices">
										<n-form-combo v-model="device.operator" :items="['>', '>=', '<', '<=', '==']"/>
										<n-form-combo v-model="device.name" 
											:filter="suggestDevices"/>
										<span @click="row.devices.splice(row.devices.indexOf(device), 1)" class="fa fa-times"></span>
									</div>
								</div>
							</div>
						</div>
					</n-collapsible>
					<n-collapsible title="Repeat" class="list" v-if="false && row.instances && $services.page.getAllArrays(page, row.id).length">
						<div class="list-actions" v-if="!Object.keys(row.instances).length">
							<button @click="addInstance(row)">Add Repeat</button>
						</div>
						<n-collapsible class="list-item" :title="key" v-for="key in Object.keys(row.instances)">
							<n-form-text :value="key" label="Name" :required="true" :timeout="600" @input="function(value) { renameInstance(row, key, value) }"/>
							<n-form-combo v-model="row.instances[key]" label="Array" :filter="function() { return $services.page.getAllArrays(page, row.id) }" />
							<div class="list-item-actions">
								<span @click="removeInstance(row, key)" class="fa fa-trash"></span>
							</div>
						</n-collapsible>
					</n-collapsible>
					<n-collapsible title="Eventing">
						<div class="padded-content">
							<n-form-combo label="Show On" v-model="row.on" :filter="getAvailableEvents"/>
						</div>
					</n-collapsible>
					<n-collapsible title="Styling">
						<div class="padded-content">
							<n-form-text label="Class" v-model="row.class"/>
						</div>
						<div class="list-actions">
							<button @click="row.styles == null ? $window.Vue.set(row, 'styles', [{class:null,condition:null}]) : row.styles.push({class:null,condition:null})">Add Style</button>
						</div>
						<div class="padded-content" v-if="row.styles">
							<n-form-section class="list-row" v-for="style in row.styles">
								<n-form-text v-model="style.class" label="Class"/>
								<n-form-text v-model="style.condition" label="Condition"/>
								<span @click="row.styles.splice(row.styles.indexOf(style), 1)" class="fa fa-times"></span>
							</n-form-section>
						</div>
					</n-collapsible>
				</n-form>
			</n-sidebar>
		</component>
	</component>
</template>

<template id="n-prompt">
	<div class="n-prompt">
		<div class="n-prompt-content">
			<slot></slot>
		</div>
	</div>
</template>

<template id="n-absolute">
	<div class="n-absolute" :style="getStyles()" v-auto-close="function() { if (autoclose) $emit('close') }">
		<div class="n-absolute-content">
			<slot></slot>
		</div>
	</div>
</template>

<template id="page-sidemenu">
	<div class="page-sidemenu">
		<div v-for="row in rows" class="row">
			<div class="page-sideentry" @mouseout="mouseOut($event, row)" :class="{'selected': selected && selected.id == row.id}"
					@dragover="acceptDragRow($event, row)"
					@dragend="$services.page.clearDrag($event)"
					@drop="dropRow($event, row)"
					@mouseover="mouseOver($event, row)">
				<span class="fa opener" @click="toggleRow(row)" :class="{'fa-chevron-down': opened.indexOf(row.id) >= 0, 'fa-chevron-right': opened.indexOf(row.id) < 0}"></span>
				<span class="name" @click="selectRow(row)" 
					@dragstart="dragRow($event, row)"
					:draggable="true" 
					@click.ctrl="scrollIntoView(row)">{{row.name ? row.name : (row.class ? row.class : row.id)}}</span>
				<div class="collapser">
					<span class="fa" :class="{'fa-eye': !row.collapsed, 'fa-eye-slash': row.collapsed}" @click="row.collapsed = !row.collapsed"></span>
					<span class="fa fa-times" @click="$emit('removeRow', row)"></span>
				</div>
				<div class="page-sideentry-menu" v-if="false">
					<button @click="configureRow(row)"><span class="fa fa-magic"></span></button
					><button @click="up(row)"><span class="fa fa-chevron-circle-up"></span></button
					><button @click="down(row)"><span class="fa fa-chevron-circle-down"></span></button
					><button @click="addCell(row)"><span class="fa fa-plus" title="Add Cell"></span></button
					><button @click="copyRow(row)"><span class="fa fa-copy" title="Copy Row"></span></button
					><button v-if="$services.page.copiedCell" @click="pasteCell(row)"><span class="fa fa-paste" title="Paste Cell"></span></button
					><button @click="$emit('removeRow', row)"><span class="fa fa-times" title="Remove Row"></span></button>
				</div>
			</div>
			<div v-show="row.cells && opened.indexOf(row.id) >= 0" class="cells">
				<div v-for="cell in row.cells" class="cell">
					<div class="page-sideentry" @mouseout="mouseOut($event, row, cell)" :class="{'selected': selected && selected.id == cell.id}"
							@dragend="$services.page.clearDrag($event)"
							@dragover="acceptDragCell($event, row, cell)"
							@drop="dropCell($event, row, cell)"
							@mouseover="mouseOver($event, row, cell)">
						<span class="cell-icon fa" :class="['component-' + cell.alias, {'is-empty': !cell.alias }]"></span>
						<span class="name" @click="selectCell(row, cell)" 
							@dragstart="dragCell($event, row, cell)"
							:draggable="true" 
							@click.ctrl="scrollIntoView(row, cell)">{{cell.name ? cell.name : (cell.class ? cell.class : (cell.alias ? cell.alias : cell.id))}}</span>
						<div class="configurer">
							<span class="fa fa-cog" v-if="hasConfigure(cell)" @click="configure(cell)"></span>
							<span class="fa fa-times" @click="removeCell(row.cells, cell)"></span>
						</div>
						<div class="page-sideentry-menu" v-if="false">
							<button @click="configureCell(row, cell);"><span class="fa fa-magic" title="Set Cell Content"></span></button
							><button @click="configure(cell)" v-if="cell.alias"><span class="fa fa-cog" title="Configure Cell Content"></span></button    
							><button @click="left(row, cell)" v-if="row.cells.length >= 2"><span class="fa fa-chevron-circle-left"></span></button
							><button @click="right(row, cell)" v-if="row.cells.length >= 2"><span class="fa fa-chevron-circle-right"></span></button
							><button @click="addRow(cell)"><span class="fa fa-plus" title="Add Row"></span></button
							><button @click="removeCell(row.cells, cell)"><span class="fa fa-times" title="Remove Cell"></span></button
							><button @click="copyCell(cell)"><span class="fa fa-copy" title="Copy Cell"></span></button
							><button @click="pasteRow(cell)" v-if="$services.page.copiedRow"><span class="fa fa-paste" title="Paste Row"></span></button>   
						</div>
					</div>
					<page-sidemenu v-show="cell.rows" :rows="cell.rows" :page="page" v-bubble:select :selected="selected"
						@open="function() { if (opened.indexOf(row) < 0) opened.push(row.id) }"
						v-bubble:open
						@removeRow="function(row) { $confirm({message:'Are you sure you want to remove this row?'}).then(function() { cell.rows.splice(cell.rows.indexOf(row), 1) }) }"/>
				</div>
			</div>
		</div>
	</div>
</template>


