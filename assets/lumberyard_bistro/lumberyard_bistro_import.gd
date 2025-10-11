@tool # Needed so it runs in editor.
extends EditorScenePostImport
## Gosh, what a mess! It's almost as if this isn't a smart way of doing things...

const GLOBAL_OFFSET := Vector3(1.154, -0.25, -7.0)
const GLOBAL_ROTATION := Vector3(0.0, 65.1, 0.0)

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene: Node) -> Object:
	# Add basic script to get wind animation playing in the editor.
	var script := GDScript.new()
	script.source_code = '''
@tool
extends Node
func _ready() -> void:
	if Engine.is_editor_hint():
		$AnimationPlayer.play($AnimationPlayer.get_animation_list()[0])
'''
	script.reload()
	scene.set_script(script)

	_overwrite_properties(scene)
	return scene # Remember to return the imported scene

# Recursive function that is called on every node
# (for demonstration purposes; EditorScenePostImport only requires a `_post_import(scene)` function).
func _overwrite_properties(node: Node) -> void:
	if node == null: return

	if node.name =='BistroExterior':
		node.position = GLOBAL_OFFSET
		node.rotation_degrees = GLOBAL_ROTATION

	## Some Godot/scene-specific overrides for various materials/meshes...
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mesh: ArrayMesh = mesh_instance.mesh

		var id := int(mesh_instance.name.right(4))

		for surface in range(mesh.get_surface_count()):
			var mat: BaseMaterial3D = mesh.surface_get_material(surface)
			var surface_name := mesh.surface_get_name(surface)

			if id in [6231, 6225, 6185, 4853]:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mat.emission_enabled = false

#region glass
			if surface_name in ['Emissive_StreetLight', 'Vespa_Odometer_Glass', 'Spotlight_Glass_Emissive', 'MenuSign_02_Glass']:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.metallic = 0.25
				mat.metallic_specular = 1.0
				mat.rim_enabled = true
				mat.rim_tint = 1.0

				if surface_name == 'Spotlight_Glass_Emissive':
					mat.roughness = 0.5
					mat.albedo_texture = null
					mat.albedo_color = Color(0.5, 0.5, 0.5, 0.5)
					mat.rim = 0.5
					mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
				elif surface_name == 'MenuSign_02_Glass':
					mat.metallic = 1.0
					mat.roughness = 0.01
					mat.albedo_texture = null
					mat.albedo_color = Color(1, 1, 1, 0.5)
				else:
					mat.roughness = 0.15
					mat.albedo_color = Color(0.5, 0.5, 0.5, 0.2)

				if 'Lantern_Wind' in mesh_instance.name:
					mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			elif surface_name == 'MASTER_Glass_Exterior':
				mat.metallic = 0.5
				mat.roughness = 0.01
#endregion

#region stringlights
			elif surface_name == 'Paris_StringLights_01_White_Color':
				mat.backlight_enabled = true
				mat.backlight = Color(0.4, 0.4, 0.4, 1)
				mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

			elif 'Paris_StringLights' in surface_name:
				mat.backlight_enabled = true
				mat.backlight = mat.emission*0.25 + Color.WHITE*0.25
				mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

			elif surface_name == 'Stringlights':
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
#endregion

#region fabric
			elif 'Fabric_Red' in surface_name or 'Hotel_Fabric' in surface_name:
				mat.backlight_enabled = true
				mat.backlight = Color(0.6, 0.35, 0.0)
#endregion

#region foliage
			elif 'Foliage' in surface_name and 'Trunk' not in surface_name and 'branches' not in surface_name:
				mat.backlight_enabled = true
				mat.backlight = Color(0.65, 0.625, 0.0625)
				mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

				if ('Ivy' in surface_name or 'Flowers' in surface_name) and not id in [4049, 6047, 6049, 4031, 4041]:
					mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

				if 'Linde' in surface_name and 'Leaves' in surface_name:
					mat.disable_receive_shadows = true

				if 'Ivy' in surface_name or 'Hedge' in surface_name:
					mat.normal_scale = 3.0

				if 'Ivy' in surface_name or 'Linde' in surface_name or surface_name == 'Foliage_Flowers.DoubleSided':
					mesh_instance.gi_lightmap_texel_scale = 0.125
				else:
					mat.cull_mode = BaseMaterial3D.CULL_BACK
					mesh_instance.gi_lightmap_texel_scale = 0.5

				if 'Leaves' in surface_name:
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX

				mesh_instance.lod_bias = 0.075
#endregion

#region vespa
			elif 'Vespa' in surface_name:
				mesh_instance.layers = 0x2
				mesh_instance.gi_lightmap_texel_scale = 0.5
				if 'Headlight' in surface_name:
					# Fake refraction
					mat.metallic = 0.25
					mat.metallic_specular = 0.25
					mat.normal_scale = -2.0
#endregion

#region wood
			elif 'Wood_Painted' in surface_name or 'Bistro_Main_Door' in surface_name:
				mat.anisotropy_enabled = true
				mat.anisotropy = 0.25
				if 'Bistro_Main_Door' in surface_name:
					mat.metallic_specular = 0.25

			elif 'Side_Letters' in surface_name:
				mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			elif surface_name == 'Bistro_Sign_Letters_Emissive':
				mat.emission_enabled = true
				mat.emission_intensity = 6500.0 # Adjust emission for physical light units (nits)
#endregion

#region buildings
			elif surface_name == 'MASTER_Forge_Metal':
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

			elif 'Roofing' in surface_name or 'Brick' in surface_name or 'Menu' in surface_name or 'Shopsign' in surface_name:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
#endregion

		# Reduce lightmap texel scale for roofs, interiors, etc. so we increase the lightmap
		# detail on meshes that actually matter at roughly the same output file size.
		if id in [5461, 5001, 5529, 5505, 4279, 4281, 4287, 4299, 4581, 4285, 4283, 4289, 5783, 5603, 5623, 5643, 5805, 5759, 5707, 5711, 4301, 4291, 5693, 5831, 5823, 5835, 5677, 5659]:
			mesh_instance.gi_lightmap_texel_scale = 0.125
		elif id in [5321, 5351, 5327, 5269, 4773, 4849, 4851, 4007, 4009, 3975, 3963, 3977, 3965, 3993, 3991, 3989, 3987, 3995, 3997, 3931, 3933, 6235, 6245, 5347, 5341, 5303, 5169, 4933, 4913, 5373, 5411, 5453, 5517, 4957, 5493, 5409, 4979, 4165, 4997, 5891, 4237]:
			mesh_instance.gi_lightmap_texel_scale = 0.25
		elif id in [5421, 5487, 5423, 4965, 5379, 5511, 4967, 4939, 5137, 4363]:
			mesh_instance.gi_lightmap_texel_scale = 0.4
		elif id in [5699, 5683, 5667]:
			mesh_instance.gi_lightmap_texel_scale = 0.925
		elif id in [4889, 4909, 4901]:
			mesh_instance.gi_lightmap_texel_scale = 2.75
		elif id in [4479, 4481, 5565, 5573]:
			mesh_instance.gi_lightmap_texel_scale = 3.5

		if 'Chimney' in mesh_instance.name or 'StreetLight' in mesh_instance.name:
			mesh_instance.gi_lightmap_texel_scale = 0.5
		elif 'Aerial' in mesh_instance.name:
			mesh_instance.gi_lightmap_texel_scale = 0.125

		# Rotate chairs (as they are straight in base mesh)
		if 'Chair' in mesh_instance.name:
			if id in [5943, 5941, 5939, 5937, 5935]:
				mesh_instance.rotate_object_local(Vector3.UP, deg_to_rad(18.0))
			elif id in [5921, 5919, 5917, 5915]:
				mesh_instance.rotate_object_local(Vector3.UP, deg_to_rad(-17.0))
			elif id in [5949, 5947, 5945, 5931, 5929, 5911]:
				mesh_instance.rotate_object_local(Vector3.UP, deg_to_rad(9.0))
			elif id in [5927, 5925, 5923, 5913, 5909, 5907]:
				mesh_instance.rotate_object_local(Vector3.UP, deg_to_rad(-12.0))


	elif node is AnimationPlayer:
		node.autoplay = node.get_animation_list()[0]

	for child in node.get_children():
		_overwrite_properties(child)
