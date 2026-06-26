import SwiftUI

struct SignInView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = SignInViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $viewModel.mode) {
                        ForEach(SignInMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

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

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
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
                                ProgressView()
                            } else {
                                Text(viewModel.mode.title)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .navigationTitle("Shopping")
        }
    }
}

#Preview {
    SignInView()
        .environment(PreviewData.signedOutAppModel)
}
