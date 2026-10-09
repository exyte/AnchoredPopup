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
    }

    var content: some View {
        GeometryReader { proxy in
            VStack {
                Image(.profile)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: imageHeight(for: proxy.size.height))
                    .clipped()

                Spacer()

                profileDetails
                    .padding(.horizontal, 20)
                bottomButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
    }

    var profileDetails: some View {
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
    }

    var bottomButtons: some View {
        HStack {
            Image(.profileTicketBG)
                .overlay {
                    Image(.profileTicket)
                }
                .size(60)
                .useAsPopupAnchor(id: "send_invite") {
                    InviteView()
                        .padding(16)
                } customize: {
                    $0.position(.screenRelative(.bottomTrailing, boundsMode: .free))
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
                    $0.position(.anchorRelative(.bottomTrailing, boundsMode: .free))
                        .background(.none)
                        .isBackgroundPassthrough(true)
                }
        }
    }

    func imageHeight(for availableHeight: CGFloat) -> CGFloat {
        min(300, max(140, availableHeight * 0.32))
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
