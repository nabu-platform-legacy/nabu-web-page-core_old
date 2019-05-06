<template id="a-notification">
	
	<div class="a-notification" :class="['notification-' + type, 'notification-' + severity]">
		
		<div class="icon-wrapper" :class="severity">
			<span class="icon" :class="iconClass"></span>
		</div>
		
		<div class="content">
			<div class="message" v-if="message">{{ message }}</div>
			<p class="description" v-if="description">{{ description }}</p>
			<component v-if="component" :is="component" :notification="$self" :close="close"/>
		</div>
		
		<div class="close" @click="close" v-if="!component">
			<span class="icon fa fa-times"></span>
		</div>
		
	</div>
	
</template>
