import SwiftUI

struct SignInView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = SignInViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 10) {
                        WanderCartWordmark()

                        Text("Shop the feeling. Keep the money.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)

                Section {
                    Picker("Mode", selection: $viewModel.mode) {
                        ForEach(SignInMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .brandListRow()

                Section {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(
                            viewModel.mode == .signIn ? .password : .newPassword
                        )
                }
                .brandListRow()

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(Color.brandAccentCoral)
                    }
                    .brandListRow()
                }

                Section {
                    Button {
                        Task {
                            await viewModel.submit(using: appModel)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isSubmitting {
                                AppLoadingIndicator(
                                    accessibilityLabel: "Signing in",
                                    size: 22
                                )
                            } else {
                                Text(viewModel.mode.title)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canSubmit)
                }
                .listRowBackground(Color.clear)
            }
            .brandPageBackground()
            .navigationTitle("")
        }
    }
}

#Preview {
    SignInView()
        .environment(PreviewData.signedOutAppModel)
}
