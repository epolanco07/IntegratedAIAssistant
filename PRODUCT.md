# Product

<!-- impeccable:product-schema 1 -->

## Platform

macOS native

## Users

The owner uses JARVIS as a personal assistant from a Mac, primarily through voice conversation and secondarily through focused productivity actions.

## Product Purpose

JARVIS provides a calm, centralized surface for conversing with an assistant while leaving space for future memory, integrations, and authorized automation.

## Positioning

The primary interaction is voice: the application makes the assistant’s listening, processing, and speaking state immediately legible through a single focused encounter rather than treating voice as a secondary chat feature.

## Operating Context

The app runs as a native macOS workspace. The user can speak to the assistant, review a transcript, switch conversations, and later access integrations through the local backend.

## Capabilities and Constraints

- The current implementation uses local mock chat and offline voice abstractions.
- Voice conversation, integrations, and browser automation must remain clearly labelled as unavailable until their backend services are connected.
- The Swift client communicates only with the local backend; it never holds permanent API credentials or connects directly to a remote browser agent.

## Brand Commitments

JARVIS is composed, precise, helpful, and quietly futuristic. The user requested a voice-first orb as the primary experience, with inspiration drawn from the functional clarity of fictional advanced-assistant interfaces, without copying their protected UI assets or layouts.

## Evidence on Hand

The repository contains a SwiftUI macOS application with dashboard, chat, voice, and settings screens. It contains no connected backend or real integration data.

## Product Principles

- Conversation begins without hunting for controls.
- Status is visible but never theatrical.
- Sophistication comes from hierarchy and motion, not visual clutter.
- Utilities support the voice encounter from adjacent views.
