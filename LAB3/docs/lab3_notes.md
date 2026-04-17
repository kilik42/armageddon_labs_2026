# LAB3 Notes

## Option A Adaptation
For project continuity, the existing us-west-2 stack is treated conceptually as the Tokyo / primary data-authority side.

This preserves the intended architecture pattern without rebuilding the full primary stack in ap-northeast-1.

## Secondary Region
The São Paulo region was built as the secondary compute side of the architecture.

## Main Technical Challenge
The most important technical objective in LAB3A was creating a private multi-region corridor using:
- regional TGWs
- TGW peering
- bidirectional routing

## Key Outcome
The architecture now supports private backbone connectivity between the primary and secondary regional environments.

# LAB3 – Multi-Region Architecture

## Overview
LAB3 extends the single-region architecture into a multi-region design using AWS Transit Gateway.

## Architecture
Primary VPC (us-west-2) → Primary TGW → TGW Peering → São Paulo TGW → Secondary VPC (sa-east-1)

## Key Components
- Primary Transit Gateway (us-west-2)
- Secondary Transit Gateway (sa-east-1)
- VPC attachments in both regions
- TGW peering connection between regions
- Bidirectional routing between VPC CIDRs

## Validation
Validation confirmed:
- Both TGWs exist and are available
- VPC attachments are active
- TGW peering is established and available
- Routes exist in both directions between regions

## Result
The architecture enables private, cross-region communication using AWS backbone networking, modeling real-world distributed systems design.