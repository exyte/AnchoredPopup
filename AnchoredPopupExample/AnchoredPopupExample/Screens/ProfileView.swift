//
//  ProfileView.swift
//  AnchoredPopupExample
//
//  Created by Alisa Mylnikova on 18.02.2025.
//

import SwiftUI
import AnchoredPopup

struct ProfileView: View {
    @Environment(\.anchoredPopupDismiss) var dismiss

    var body: some View {
        content
            .ignoresSafeArea()
            .background(Color.white)
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss?()
                } label: {
                    Image(.navBack)
                        .padding(8)
                }
                .padding(.top, 45)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Image(.profileTicketBG)
                        .overlay {
                            Image(.profileTicket)
                        }
                        .size(60)
                        .useAsPopupAnchor(id: "send_invite") {
                            InviteView()
                        } customize: {
                            $0.position(.screenRelative(.bottomTrailing))
                                .closeOnTap(false)
                                .background(.color(.black.opacity(0.4)))
                        }

                    Spacer()

                    Circle().styled(.popupLightPeriwinkle)
                        .overlay {
                            Image(.question)
                        }
                        .size(56)
                        .useAsPopupAnchor(id: "questions_view") {
                            QuestionsView()
                        } customize: {
                            $0.position(.auto)
                                .background(.none)
                                .isBackgroundPassthrough(true)
                        }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
    }

    var content: some View {
        VStack {
            Image(.profile)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: 330)

            Spacer()

            VStack {
                Text("Online").plexMedium(16, .popupViolet)
                Text("Mary Goodwin").chakraMedium(24)

                Spacer()

                HStack(spacing: 12) {
                    profileButton(.profileWorkout, "Workout plan")
                    profileButton(.profileFavorites, "Favourites")
                }

                Spacer()

                profileCell("Notifications")
                profileCell("Settings")
                profileCell("FAQ")
                profileCell("Support")
                profileCell("Log out")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    func profileButton(_ image: ImageResource, _ title: String) -> some View {
        HStack {
            Circle().foregroundStyle(.popupLavender)
                .size(42)
                .overlay {
                    Image(image)
                }
            Spacer()
            Text(title).chakraMedium(15)
            Spacer()
        }
        .padding(6)
        .overlay {
            RoundedRectangle(cornerRadius: .infinity)
                .styled(.clear, border: .popupAzureishWhite, 1)
        }
    }

    @ViewBuilder
    func profileCell(_ title: String) -> some View {
        HStack {
            Text(title).chakra(20)
            Spacer()
            Image(.arrowRight)
        }
        Spacer()
    }
}
