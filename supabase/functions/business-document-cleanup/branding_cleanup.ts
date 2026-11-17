import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.4'

type BrandingCleanupLease = {
  company_id: string
  operation_id: string
  bucket_id: string
  storage_reference: string
}

export type BrandingCleanupResult = {
  failedToClaim: boolean
  inspected: number
  cleaned: number
  deferred: number
}

const brandingKey = /^companies\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\/logos\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(png|jpg|jpeg|webp)$/

/// Operational cleanup belongs to the trusted scheduled service, not Flutter.
/// All candidate selection and reference/lease checks are database-owned.
export async function cleanupCompanyBranding(
  client: SupabaseClient,
): Promise<BrandingCleanupResult> {
  const { data, error } = await client.rpc('claim_company_branding_cleanup', {
    p_batch_limit: 25,
  })
  if (error) {
    console.error('Branding cleanup claim failed', error.code)
    return { failedToClaim: true, inspected: 0, cleaned: 0, deferred: 0 }
  }

  const leases = (data ?? []) as BrandingCleanupLease[]
  let cleaned = 0
  let deferred = 0

  async function recordFailure(
    lease: BrandingCleanupLease,
    errorCode: 'preflight_failed' | 'storage_remove_failed' |
      'cleanup_complete_failed',
  ): Promise<void> {
    const { error: trackingError } = await client.rpc(
      'defer_company_branding_cleanup',
      {
        p_company_id: lease.company_id,
        p_operation_id: lease.operation_id,
        p_error_code: errorCode,
      },
    )
    if (trackingError) {
      // The server retains the pending lease; it will be retried after TTL.
      console.warn('Branding cleanup defer tracking failed', trackingError.code)
    }
  }

  for (const lease of leases) {
    const match = brandingKey.exec(lease.storage_reference)
    if (
      lease.bucket_id !== 'company-branding' ||
      match === null ||
      match[1] !== lease.company_id
    ) {
      deferred++
      await recordFailure(lease, 'preflight_failed')
      continue
    }

    // The Storage service-role key bypasses normal member RLS. A privileged
    // database preflight rechecks BOTH active-company and issued-invoice refs
    // immediately before deleting bytes. No ordinary user can invoke it.
    const { data: safe, error: verificationError } = await client.rpc(
      'verify_company_branding_cleanup_lease',
      {
        p_company_id: lease.company_id,
        p_operation_id: lease.operation_id,
      },
    )
    if (verificationError || safe !== true) {
      deferred++
      await recordFailure(lease, 'preflight_failed')
      continue
    }

    // Supabase Storage API deletes bytes and object metadata together.
    // Never DELETE storage.objects records directly in SQL.
    const { error: removeError } = await client.storage
      .from('company-branding')
      .remove([lease.storage_reference])
    if (removeError) {
      deferred++
      console.warn('Branding cleanup Storage remove deferred', removeError.name)
      await recordFailure(lease, 'storage_remove_failed')
      continue
    }

    // Completion is conditional on the object being gone and references
    // remaining absent. Unknown network outcomes are retried, not discarded.
    const { error: finishError } = await client.rpc(
      'complete_company_branding_cleanup',
      {
        p_company_id: lease.company_id,
        p_operation_id: lease.operation_id,
      },
    )
    if (finishError) {
      deferred++
      console.warn('Branding cleanup completion deferred', finishError.code)
      await recordFailure(lease, 'cleanup_complete_failed')
    } else {
      cleaned++
    }
  }

  return {
    failedToClaim: false,
    inspected: leases.length,
    cleaned,
    deferred,
  }
}
