import SwiftUI

struct AuthSelectionView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6)]),
                               center: .center,
                               startRadius: 50,
                               endRadius: 500)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(Color.black.opacity(0.1))
                
                VStack {
                    ZStack {
                        Image(systemName: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.black)
                        
                        ZStack {
                            Circle()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black)
                            
                            Text("P")
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -30, y: -30)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}
