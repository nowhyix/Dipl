import SwiftUI

struct ErrorMessageView: View {
    let message: String
    let onClose: () -> Void
    
    // Добавляем состояние для таймера
    @State private var isVisible = true
    
    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible = false
                        onClose()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(8)
            .padding(.horizontal)
            .shadow(radius: 5)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 5)
        .opacity(isVisible ? 1 : 0) // Анимируем исчезновение
        .animation(.easeInOut, value: isVisible)
        .onAppear {
            // Устанавливаем таймер на 5 секунд
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    isVisible = false
                    onClose()
                }
            }
        }
    }
}
