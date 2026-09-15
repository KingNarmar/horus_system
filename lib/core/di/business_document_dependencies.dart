import '../data/supabase/supabase_client_provider.dart';
import '../documents/data/datasources/business_document_storage_remote_data_source.dart';
import '../documents/data/repositories/business_document_storage_repository_impl.dart';
import '../documents/data/services/business_document_object_path_builder.dart';
import '../documents/domain/repositories/business_document_storage_repository.dart';

abstract final class BusinessDocumentDependencies {
  static BusinessDocumentStorageRepository createRepository() {
    return BusinessDocumentStorageRepositoryImpl(
      remoteDataSource: SupabaseBusinessDocumentStorageRemoteDataSource(
        SupabaseClientProvider.client,
      ),
      pathBuilder: BusinessDocumentObjectPathBuilder(),
    );
  }
}
