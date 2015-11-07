// vim: noet ts=4 sw=4
#include "void.h"

static inline void_asset_mesh_t *_void_asset_mesh_init(void_asset_mesh_t *mesh) {
	if (mesh == NULL) {
		log_msg(LOG_ERR, "New mesh is NULL.");
		goto error;
	}

	mesh->vertices = vector_new(sizeof(unsigned int), 64);
	if (mesh->vertices == NULL) {
		goto error;
	}

	mesh->uvs = vector_new(sizeof(unsigned int), 64);
	if (mesh->uvs == NULL) {
		goto error;
	}

	mesh->normals = vector_new(sizeof(unsigned int), 64);
	if (mesh->normals == NULL) {
		goto error;
	}

	return mesh;

error:
	if (mesh->vertices != NULL)
		vector_free(mesh->vertices);
	if (mesh->uvs != NULL)
		vector_free(mesh->uvs);
	if (mesh->normals != NULL)
		vector_free(mesh->normals);
	if (mesh != NULL)
		free(mesh);

	return NULL;
}

int void_asset_import_mesh(const char *path, void_asset_mesh_t *out_mesh) {
	_void_asset_mesh_init(out_mesh);
	FILE *mesh_file = NULL;

	if (out_mesh == NULL)
		goto error;

	mesh_file = fopen(path, "r");
	if (mesh_file == NULL) {
		log_msg(LOG_ERR, "Could not open mesh file.");
		goto error;
	}

	char line_buf[256] = {0};
	vector *temp_vertices = vector_new(sizeof(void_vector3_t), 128);
	vector *temp_uvs = vector_new(sizeof(void_vector2_t), 128);
	vector *temp_normals = vector_new(sizeof(void_vector3_t), 128);

	vector *vertex_indices = vector_new(sizeof(unsigned int), 128);
	vector *uv_indices = vector_new(sizeof(unsigned int), 128);
	vector *normal_indices = vector_new(sizeof(unsigned int), 128);

	while (fgets(line_buf, sizeof(line_buf), mesh_file)) {
		if (line_buf[0] == 'v') {
			if (line_buf[1] == ' ') {
				/* Vertex import. */
				void_vector3_t vertex;
				sscanf(line_buf, "v "VS_CHAR" "VS_CHAR" "VS_CHAR"\n", &vertex.x, &vertex.y, &vertex.z);
				vector_append(temp_vertices, &vertex, sizeof(vertex));
			} else if (line_buf[1] == 't') {
				/* UV Index import. */
				void_vector2_t uv_vertex;
				sscanf(line_buf, "vt "VS_CHAR" "VS_CHAR"\n", &uv_vertex.x, &uv_vertex.y);
				vector_append(temp_uvs, &uv_vertex, sizeof(uv_vertex));
			} else if (line_buf[1] == 'n') {
				/* Normal import. */
				void_vector3_t normal_vertex;
				sscanf(line_buf, "vn "VS_CHAR" "VS_CHAR" "VS_CHAR"\n", &normal_vertex.x, &normal_vertex.y, &normal_vertex.z);
				vector_append(temp_normals, &normal_vertex, sizeof(normal_vertex));
			}
		}

		if (line_buf[0] == 'f') {
			/* Defines a face. */
#define MAX 3
			unsigned int uv_vec[MAX] = {0};
			unsigned int normal_vec[MAX] = {0};
			unsigned int vertex_vec[MAX] = {0};

			int matches = sscanf(line_buf, "f %d/%d/%d %d/%d/%d %d/%d/%d\n",
									   &vertex_vec[0], &uv_vec[0], &normal_vec[0],
									   &vertex_vec[1], &uv_vec[1], &normal_vec[1],
									   &vertex_vec[2], &uv_vec[2], &normal_vec[2]);

			if (matches != 9){
				log_msg(LOG_ERR, "Cannot parse obj file. Line: %s", line_buf);
				goto error;
			}

			int i = 0;
			for (i = 0; i < MAX; i++) {
				vector_append(out_mesh->uvs, &uv_vec[i], sizeof(unsigned int));
				vector_append(out_mesh->normals, &normal_vec[i], sizeof(unsigned int));
				vector_append(out_mesh->vertices, &vertex_vec[i], sizeof(unsigned int));
			}
		}
	}

	size_t i = 0;
	for (i = 0; i < vertex_indices->count; i++) {
		unsigned int vertex_index = *(unsigned int*)vector_get(vertex_indices, i);
		unsigned int uv_index = *(unsigned int*)vector_get(uv_indices, i);
		unsigned int normal_index = *(unsigned int*)vector_get(normal_indices, i);

		const void_vector3_t vertex = *(const void_vector3_t *)vector_get(temp_vertices, vertex_index - 1);
		const void_vector2_t uv = *(const void_vector2_t *)vector_get(temp_uvs, uv_index - 1);
		const void_vector3_t normal = *(const void_vector3_t *)vector_get(temp_normals, normal_index - 1);

		vector_append(out_mesh->vertices, &vertex, sizeof(vertex));
		vector_append(out_mesh->uvs, &uv, sizeof(uv));
		vector_append(out_mesh->normals, &normal, sizeof(normal));
	}

	vector_free(vertex_indices);
	vector_free(uv_indices);
	vector_free(normal_indices);

	vector_free(temp_vertices);
	vector_free(temp_uvs);
	vector_free(temp_normals);

	fclose(mesh_file);
	return TRUE;

error:
	if (mesh_file != NULL)
		fclose(mesh_file);

	return FALSE;
}

