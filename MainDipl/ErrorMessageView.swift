import SwiftUI

struct ErrorMessageView: View {
    let message: String
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                Spacer()
                
                Button(action: onClose) {
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
            
            Spacer() // Добавляем Spacer чтобы выровнять по верху
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Выравниваем по верху
        .padding(.top, 5) // Добавляем отступ сверху
    }
}
