//
//  Popups.swift
//  AnchoredPopupExample
//
//  Created by Alisa Mylnikova on 22.01.2025.
//

import SwiftUI
import AnchoredPopup

struct MainMenuView: View {
    var body: some View {
        ZStack {
            Color.popupDarkViolet
                .cornerRadius(30)

            VStack(alignment: .leading, spacing: 0) {
                Label {
                    Text("Start workout").chakra(15, .white)
                } icon: {
                    Image(.mainMenuDumbbell)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)

                Color.popupViolet.frame(height: 1)
                    .padding(16, 12)

                Label {
                    Text("Record your exercises ").chakra(15, .white)
                } icon: {
                    Image(.mainMenuCamera)
                }
                .padding(.horizontal, 20)

                Color.popupViolet.frame(height: 1)
                    .padding(16, 12)

                Label {
                    Text("Watch lesson").chakra(15, .white)
                } icon: {
                    Image(.mainMenuLibrary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                ZStack {
                    Circle().foregroundStyle(.popupViolet)
                        .size(60)
                    Image(.cross)
                }
                .onTapGesture {
                    AnchoredPopup.launchShrinkingAnimation(id: "main_menu")
                }
            }
        }
        .fixedSize()
    }
}

struct CongratulationsView: View {
    @Environment(\.anchoredPopupDismiss) var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Image(.congratulations)
            Text("Congratulations!").chakraMedium(24)
            Text("In two weeks, you did 12 workouts and burned 2671 calories. That's 566 calories more than last month. Continue at the same pace and the result will please you.")
                .plex(15, .popupGray3)
                .multilineTextAlignment(.center)

            Button {
                dismiss?()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.popupViolet)
                        .greedyWidth()
                    Text("THANKS").plexMedium(18, .white)
                        .padding(18)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .frame(maxWidth: 300)
        .padding(24, 40)
        .background {
            Color.white.cornerRadius(20)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss?()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(.popupAzureishWhite)
                        .size(32)
                    Image(.xmark)
                }
            }
            .padding(16, 20)
        }
        .padding(40)
    }
}

struct InviteView: View {
    @Environment(\.anchoredPopupDismiss) var dismiss

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(.giftBG)
                Image(.gift)
            }
            Text("Invite friends. Get free Plus").chakraMedium(20)
                .multilineTextAlignment(.center)
            Text("Get month of free Workout Plus for every friend who joins via your invite link.")
                .plex(13, .popupGray3)
                .multilineTextAlignment(.center)

            Button {
                dismiss?()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.popupViolet)
                        .greedyWidth()
                    Text("SEND INVITE").plexMedium(18, .white)
                        .padding(18)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 20)
        }
        .frame(width: 230)
        .padding(16, 24)
        .background {
            Color.white.cornerRadius(20)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss?()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(.popupAzureishWhite)
                        .size(32)
                    Image(.xmark)
                }
            }
            .padding(12)
        }
    }
}

struct QuestionsView: View {

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Help center")
                Text("Support forum")
                Text("YouTube videos")
                Text("Submit feedback")
                Text("Ask the community")

                Color.popupSeparator.frame(height: 0.5)
                    .padding(.horizontal, -4)

                Text("Change language...")
            }
            .chakraLight(15, .popupGray5)
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 4)

            HStack {
                Spacer()
                Circle().styled(.popupLightPeriwinkle)
                    .overlay {
                        Image(.cross)
                    }
                    .size(56)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 28).styled(.popupAzureishWhite)
        }
        .frame(width: 230)
    }
}
