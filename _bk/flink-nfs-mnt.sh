        volumeMounts:
        - name: strjar
          mountPath: /opt/str_jar
      volumes:
      - name: strjar
        persistentVolumeClaim:
          claimName: myflk-nfs-pvc
