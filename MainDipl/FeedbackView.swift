import SwiftUI

struct FeedbackView: View {
    @State private var feedbackText = ""
    @State private var isLoading = false
    @State private var isSubmitted = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 200)
                } header: {
                    Text("Ваше сообщение")
                } footer: {
                    Text("Опишите вашу проблему или предложение")
                }
                
                Section {
                    Button(action: submitFeedback) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Отправить")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(feedbackText.isEmpty || isLoading)
                }
            }
            .navigationTitle("Обратная связь")
            .overlay(errorMessageView, alignment: .top)
            .alert("Спасибо!", isPresented: $isSubmitted) {
                Button("OK", role: .cancel) {
                    feedbackText = ""
                }
            } message: {
                Text("Ваше сообщение отправлено. Мы свяжемся с вами в ближайшее время.")
            }
        }
    }
    
    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = errorMessage {
            ErrorMessageView(message: errorMessage) {
                self.errorMessage = nil
            }
            .transition(.move(edge: .top))
            .animation(.spring(), value: errorMessage)
            .zIndex(1)
        }
    }
    
    private func submitFeedback() {
        guard !feedbackText.isEmpty else {
            errorMessage = "Пожалуйста, введите ваше сообщение"
            return
        }
        
        isLoading = true
        // Имитация отправки
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            isSubmitted = true
        }
    }
}
