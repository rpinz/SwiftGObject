//
//  GLibNotify.swift
//  GObject
//
//  Created by Rene Hexel on 27/4/17.
//  Copyright © 2017 Rene Hexel.  All rights reserved.
//
import CGLib
import GLib
import Dispatch

let lockq = DispatchQueue(label: "io.github.rhx.glib.notify.lock")

public extension ObjectProtocol {
    /// Freeze notifications
    ///
    /// - Parameter context: notification context to freeze
    func freeze(context: UnsafeMutablePointer<GObjectNotifyContext>?) -> UnsafeMutablePointer<GObjectNotifyQueue>? {
        guard let context = context else { return nil }
        let qdata = UnsafeMutablePointer(mutating: &ptr.pointee.qdata).withMemoryRebound(to: Optional<UnsafeMutablePointer<GData>>.self, capacity: 1) { $0 }
        var queue: UnsafeMutablePointer<GObjectNotifyQueue>?
        lockq.sync {
            let nq: UnsafeMutablePointer<GObjectNotifyQueue>
            if let q = g_datalist_id_get_data(qdata, context.pointee.quark_notify_queue) {
                nq = q.assumingMemoryBound(to: GObjectNotifyQueue.self)
            } else {
                nq = g_slice_new0()
                nq.pointee.context = context
                g_datalist_id_set_data_full(qdata, context.pointee.quark_notify_queue, UnsafeMutableRawPointer(nq)) {
                    guard let nq = $0?.assumingMemoryBound(to: GObjectNotifyQueue.self) else { return }
                    g_slist_free(nq.pointee.pspecs)
                    g_slice_free(nq)
                }
            }
            if nq.pointee.freeze_count >= 65535 {
                g_log("Freeze count for \(typeName) at \(ptr) is larger than 65536 - called freeze(context:) too often (forgot to call thaw(notifyQueue:) or infinite loop)", level: .level_critical)
            } else {
                nq.pointee.freeze_count += 1
            }
            queue = nq
        }
        return queue
    }

    /// Unfreeze notifications
    ///
    /// - Parameter queue: notification queue to thaw
    func thaw(queue nq: UnsafeMutablePointer<GObjectNotifyQueue>) {
        guard let context = nq.pointee.context else { return }
        var pspecs = Array<UnsafeMutablePointer<GParamSpec>?>()
        lockq.sync {
            guard nq.pointee.freeze_count > 0 else { return }
            nq.pointee.freeze_count -= 1
            guard nq.pointee.freeze_count == 0 else { return }

            pspecs.reserveCapacity(Int(nq.pointee.n_pspecs))
            var slist = nq.pointee.pspecs
            while let sl = slist {
                pspecs.append(sl.pointee.data.assumingMemoryBound(to: GParamSpec.self))
                slist = sl.pointee.next
            }
        }
        if !pspecs.isEmpty {
            context.pointee.dispatcher(ptr, guint(pspecs.count), &pspecs)
        }
    }
}
