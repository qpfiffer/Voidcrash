// vim: noet ts=4 sw=4
#include "void.h"

static inline void_asset_mesh_t *_void_asset_mesh_init() {
	void_asset_mesh_t *mesh = malloc(sizeof(void_asset_mesh_t));
	if (mesh == NULL) {
		log_msg(LOG_ERR, "Could not allocate memory for new mesh.");
		goto error;
	}

	mesh->vertex_indices = vector_new(sizeof(void_vector3_t), 64);
	if (mesh->vertex_indices == NULL) {
		goto error;
	}

	mesh->uv_indices = vector_new(sizeof(void_vector2_t), 64);
	if (mesh->uv_indices == NULL) {
		goto error;
	}

	mesh->normal_indices = vector_new(sizeof(void_vector3_t), 64);
	if (mesh->normal_indices == NULL) {
		goto error;
	}

	return mesh;

error:
	if (mesh->vertex_indices != NULL)
		vector_free(mesh->vertex_indices);
	if (mesh->uv_indices != NULL)
		vector_free(mesh->uv_indices);
	if (mesh->normal_indices != NULL)
		vector_free(mesh->normal_indices);
	if (mesh != NULL)
		free(mesh);

	return NULL;
}

void_asset_mesh_t *void_asset_import_mesh(const char *path) {
	FILE *mesh_file = NULL;
	void_asset_mesh_t *mesh = _void_asset_mesh_init();

	if (mesh == NULL)
		goto error;

	mesh_file = fopen(path, "r");
	if (mesh_file == NULL) {
		log_msg(LOG_ERR, "Could not open mesh file.");
		goto error;
	}

	char line_buf[256] = {0};
	while (fgets(line_buf, sizeof(line_buf), mesh_file)) {
		if (line_buf[0] == 'v') {
			if (line_buf[1] == ' ') {
				/* Vertex import. */
				void_vector3_t vertex;
				sscanf(line_buf, ""VS_CHAR" "VS_CHAR" "VS_CHAR"\n", &vertex.x, &vertex.y, &vertex.z);
				vector_append(mesh->vertex_indices, &vertex, sizeof(vertex));
			} else if (line_buf[1] == 't') {
				/* UV Index import. */
				void_vector2_t uv_vertex;
				sscanf(line_buf, ""VS_CHAR" "VS_CHAR"\n", &uv_vertex.x, &uv_vertex.y);
				vector_append(mesh->uv_indices, &uv_vertex, sizeof(uv_vertex));
			} else if (line_buf[1] == 'n') {
				/* Normal import. */
				void_vector3_t normal_vertex;
				sscanf(line_buf, ""VS_CHAR" "VS_CHAR" "VS_CHAR"\n", &normal_vertex.x, &normal_vertex.y, &normal_vertex.z);
				vector_append(mesh->normal_indices, &normal_vertex, sizeof(normal_vertex));
			}
		}

		if (line_buf[0] == 'f') {
			/* Combination of vertex, uv and then normals. */
			/* XXX: TODO
			void_vector2_t uv_vec;
			void_vector3_t normal_vec, vertex_vec;

			int matches = fscanf(file, ""VS_CHAR"/"VS_CHAR"/"VS_CHAR" "
									   VS_CHAR"/"VS_CHAR"/"VS_CHAR" "
									   VS_CHAR"/"VS_CHAR"/"VS_CHAR"\n", 
									   &uv_vec.x, &uvIndex[0], &normalIndex[0], &vertexIndex[1], &uvIndex[1], &normalIndex[1], &vertexIndex[2], &uvIndex[2], &normalIndex[2] );
			if (matches != 9){
				printf("File can't be read by our simple parser : ( Try exporting with other options\n");
				return false;
			}
			*/
		}
	}

	fclose(mesh_file);
	return mesh;

error:
	if (mesh != NULL)
		free(mesh);
	if (mesh_file != NULL)
		fclose(mesh_file);

	return NULL;
}

