# =============================================================================
# S3 Bucket for source documents
# =============================================================================
resource "aws_s3_bucket" "documents" {
  bucket        = "${var.project_name}-documents"
  force_destroy = true
}

resource "aws_s3_object" "documents_prefix" {
  bucket  = aws_s3_bucket.documents.id
  key     = "tortoise-knowledge/"
  content = ""
}

# =============================================================================
# S3 Vectors
# =============================================================================
resource "aws_s3vectors_vector_bucket" "knowledge_vectors" {
  vector_bucket_name = "${var.project_name}-vectors"
}

resource "aws_s3vectors_index" "knowledge_index" {
  index_name         = "tortoise-agents-knowledge-index"
  vector_bucket_name = aws_s3vectors_vector_bucket.knowledge_vectors.vector_bucket_name

  # Vector configuration matching Titan Text Embeddings V2
  data_type       = "float32"
  dimension       = var.vector_dimension
  distance_metric = var.distance_metric

  # Metadata configuration for filtering queries
  # Bedrock Knowledge Basesが付与するメタデータで2048バイトを超える可能性があるものをnon-filterableに設定し、S3 Vectorsの制限を回避
  metadata_configuration {
    non_filterable_metadata_keys = [
      "AMAZON_BEDROCK_TEXT",     # チャンク本体テキスト(最大容量を占める)
      "AMAZON_BEDROCK_METADATA", # ソース情報等のメタデータ
      "x-amz-bedrock-kb-source-uri",
      "x-amz-bedrock-kb-chunk-id",
      "x-amz-bedrock-kb-data-source-id"
    ]
  }
}
