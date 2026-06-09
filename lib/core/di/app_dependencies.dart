import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class AppDependencies {
  static AuthCubit createAuthCubit() {
    final authRemoteDataSource = SupabaseAuthRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final authRepository = AuthRepositoryImpl(authRemoteDataSource);

    return AuthCubit(
      loginUseCase: LoginUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
    );
  }
}
