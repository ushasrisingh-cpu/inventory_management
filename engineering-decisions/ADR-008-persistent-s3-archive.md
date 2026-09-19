# ADR 008 Independent Persistent S3 Archive

**Status:** Accepted

## Context and problem

Logs and portable database backups lose their purpose if destroying a temporary dev environment also destroys the archive.

## Decision

Place the archive bucket in a dedicated Terraform environment and state. Block public access, require secure transport, enable versioning and AES256 encryption, retain logs for 30 days, retain portable SQL backups for 90 days, and set `force_destroy = false`.

## Alternatives considered

- Create the bucket inside each application environment
- Retain only CloudWatch logs and RDS automated backups
- Store backups on a local workstation
- Use cross-region replication for the capstone

## Consequences and trade-offs

Archive lifecycle and teardown require separate commands. Retained objects continue to incur small storage charges. The design prevents routine dev destruction from deleting evidence. Cross-region replication was omitted for cost and can be added for higher recovery requirements.

## Security implications

The bucket is private, encrypted, versioned, denies insecure transport, and grants the backup task write access only under the backups prefix.

## Cost implications

Lifecycle expiration limits long-term storage. The archive remains after dev teardown, so its cost must be monitored explicitly.

## Rationale

Independent state and deletion protection align infrastructure lifecycle with the different retention requirement of recovery data.
