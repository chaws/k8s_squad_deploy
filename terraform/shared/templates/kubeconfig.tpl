apiVersion: v1
preferences: {}
kind: Config

clusters:
- cluster:
    server: ${endpoint}
    certificate-authority-data: ${cluster_auth_base64}
  name: ${kubeconfig_name}

contexts:
- context:
    cluster: ${kubeconfig_name}
    user: ${kubeconfig_name}
    namespace: default
  name: default

- context:
    cluster: ${kubeconfig_name}
    user: ${kubeconfig_name}
    namespace: squad-staging
  name: squad-staging

- context:
    cluster: ${kubeconfig_name}
    user: ${kubeconfig_name}
    namespace: squad-production
  name: squad-production

current-context: default

users:
- name: ${kubeconfig_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - eks
      - get-token
      - --cluster-name
      - ${clustername}
      - --region
      - us-east-1
      command: aws
      env:
      - name: AWS_STS_REGIONAL_ENDPOINTS
        value: regional
